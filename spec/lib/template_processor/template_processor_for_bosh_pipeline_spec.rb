require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'template_processor'
require 'ci_deployment'
require 'deployment_deployers_config'
require 'pipeline_generator'
require_relative 'test_fixtures'

describe 'BoshPipelineTemplateProcessing' do
  let(:root_deployment_name) { 'my-root-depls' }
  let(:bosh_cert) { BOSH_CERT_LOCATIONS = { root_deployment_name => 'shared/certificate.pem' }.freeze }
  let(:ops_automation_path) { '.' }
  let(:processor_context) do
    { depls: root_deployment_name,
      bosh_cert: bosh_cert,
      all_dependencies: all_dependencies,
      all_ci_deployments: all_ci_deployments,
      git_submodules: git_submodules,
      config: loaded_config,
      ops_automation_path: ops_automation_path }
  end
  let(:secrets_dirs_overview) { {} }
  let(:root_deployment_versions) { {} }
  let(:all_dependencies) do
    deps_yaml = <<~YAML
      bosh-bats:
        status: disabled
      maria-db:
        status: disabled
      shield-expe:
        stemcells:
          bosh-openstack-kvm-ubuntu-xenial-go_agent:
        releases:
          cf-routing-release:
            base_location: https://bosh.io/d/github.com/
            repository: cloudfoundry-incubator/cf-routing-release
            version: 0.169.0
        errands:
            import:
            smoke-tests:
              display-name: automated-smoke-tests
        manual-errands:
            manual-import:
            manual-smoke-tests:
              display-name: my-smoke-tests
        bosh-deployment:
          active: true
        status: enabled
      bui:
        stemcells:
          bosh-openstack-kvm-ubuntu-xenial-go_agent:
        releases:
          route-registrar-boshrelease:
            base_location: https://bosh.io/d/github.com/
            repository: cloudfoundry-community/route-registrar-boshrelease
            version: '3'
          haproxy-boshrelease:
            base_location: https://bosh.io/d/github.com/
            repository: cloudfoundry-community/haproxy-boshrelease
            version: 8.0.12
        bosh-deployment:
          active: true
        status: enabled
    YAML
    YAML.safe_load(deps_yaml)
  end
  let(:all_ci_deployments) { {} }
  let(:git_submodules) { {} }
  let(:loaded_config) do
    my_config_yaml = <<~YAML
      offline-mode:
        boshreleases: true
        stemcells: true
        docker-images: false
    YAML
    YAML.safe_load(my_config_yaml)
  end
  let(:expected_resource_types) do
    resource_types_yaml = <<~YAML
      - name: slack-notification
        type: docker-image
        source:
          repository: ((docker-registry-url))cfcommunity/slack-notification-resource
          tag: v1.4.2
      - name: bosh-deployment-v2
        type: docker-image
        source:
          repository: ((docker-registry-url))cloudfoundry/bosh-deployment-resource
          tag: v2.12.0
      - name: bosh-errand
        type: docker-image
        source:
          repository: ((docker-registry-url))cfcommunity/bosh2-errand-resource
          tag: v0.1.2
      - name: meta
        type: docker-image
        source:
          repository: ((docker-registry-url))olhtbr/metadata-resource
          tag: 2.0.1

    YAML
    YAML.safe_load(resource_types_yaml)
  end
  let(:groups) do
    [
      { 'name' => 'my-root-depls',
        'jobs' =>
         ['approve-and-delete-disabled-deployments',
          'cancel-all-bosh-tasks',
          'cloud-config-and-runtime-config-for-my-root-depls',
          'delete-deployments-review',
          'deploy-bui',
          'deploy-shield-expe',
          'execute-deploy-script',
          'init-concourse-boshrelease-and-stemcell-for-my-root-depls',
          'push-boshreleases',
          'push-stemcell',
          'recreate-all',
          'recreate-bui',
          'recreate-shield-expe',
          'retrigger-all-jobs',
          'run-errand-shield-expe-automated-smoke-tests',
          'run-errand-shield-expe-import',
          'run-manual-errand-shield-expe-manual-import',
          'run-manual-errand-shield-expe-my-smoke-tests'] },
      { 'name' => 'deploy-b', 'jobs' => ['deploy-bui'] },
      { 'name' => 'deploy-s', 'jobs' => ['deploy-shield-expe', 'run-errand-shield-expe-automated-smoke-tests', 'run-errand-shield-expe-import', 'run-manual-errand-shield-expe-manual-import', 'run-manual-errand-shield-expe-my-smoke-tests' ] },
      { 'name' => 'recreate',
        'jobs' => ['recreate-all', 'recreate-bui', 'recreate-shield-expe'] },
      { 'name' => 'utils',
        'jobs' =>
        ['approve-and-delete-disabled-deployments',
         'cancel-all-bosh-tasks',
         'cloud-config-and-runtime-config-for-my-root-depls',
         'delete-deployments-review',
         'execute-deploy-script',
         'init-concourse-boshrelease-and-stemcell-for-my-root-depls',
         'push-boshreleases',
         'push-stemcell',
         'recreate-all',
         'retrigger-all-jobs'] }
    ]
  end
  let(:enable_root_deployment_terraform) do
    ci_deployments_yaml = <<~YAML
      #{root_deployment_name}:
        terraform_config:
          state_file_path: my-tfstate-location
        target_name: my-concourse-name
        pipelines:
          #{root_deployment_name}-bosh-generated:
            config_file: path/located/in/secrets-repo/pipelines/#{root_deployment_name}-generated.yml
            vars_files:
            - another/path/located/in/secrets-repo/pipelines/credentials-iaas-specific.yml
            - #{root_deployment_name}/root-deployment.yml
    YAML
    YAML.safe_load ci_deployments_yaml
  end
  let(:expected_shield_errand_resource) do
    my_shield_errand_yaml = <<~YAML
      - name: errand-shield-expe
        icon: arrange-send-to-back
        type: bosh-errand
        source:
          target: ((bosh-target))
          client: ((bosh-username))
          client_secret: ((bosh-password))
          deployment: shield-expe
          ca_cert: shared/certificate.pem
    YAML
    YAML.safe_load(my_shield_errand_yaml)
  end
  let(:config) { { dump_output: true, output_path: @output_dir } }

  context 'when processing bosh-pipeline.yml.erb' do
    subject { TemplateProcessor.new root_deployment_name, config, processor_context }

    before(:context) do
      @output_dir = Dir.mktmpdir('generated-pipelines')
      @pipelines_output_dir = File.join(@output_dir, 'pipelines')
      @template_pipeline_name = 'bosh-pipeline.yml.erb'
      @pipelines_dir = Dir.mktmpdir('pipeline-templates')

      FileUtils.copy("concourse/pipelines/template/#{@template_pipeline_name}", @pipelines_dir)
    end

    after(:context) do
      FileUtils.rm_rf(@output_dir)
      FileUtils.rm_rf(@pipelines_dir)
    end

    let(:generated_pipeline) do
      pipeline_template = @processed_template[File.join(@pipelines_dir, @template_pipeline_name)]
      generated_pipeline_path = File.join(@pipelines_output_dir, pipeline_template)
      YAML.load_file(generated_pipeline_path)
    end

    before do
      @processed_template = subject.process(@pipelines_dir + '/*')
    end

    context 'when an errand job is defined' do
      let(:expected_shield_errand) do
        my_shield_errand_yaml = <<~YAML
          - in_parallel:
            - get: concourse-meta
              passed: [ deploy-shield-expe ]
              trigger: true
          - put: errand-shield-expe
            params:
              name: import
        YAML
        YAML.safe_load(my_shield_errand_yaml)
      end

      it 'generates an errand resource for shield boshrelease' do
        generated_errand_resource = generated_pipeline['resources'].select { |job| job['name'] == 'errand-shield-expe' }
        expect(generated_errand_resource).to match(expected_shield_errand_resource)
      end

      it 'generates an errand job for shield boshrelease with default name' do
        generated_errand_job = generated_pipeline['jobs'].select { |job| job['name'] == 'run-errand-shield-expe-import' }.flat_map { |job| job['plan'] }
        expect(generated_errand_job).to match(expected_shield_errand)
      end

      it 'generates an errand job for shield boshrelease with custom name' do
        generated_errand_job = generated_pipeline['jobs'].select { |job| job['name'] == 'run-errand-shield-expe-automated-smoke-tests' }.flat_map { |job| job['plan'] }
        expect(generated_errand_job).not_to be_nil
      end

      it 'generates a concourse job per errand for shield boshrelease' do
        generated_errand_jobs = generated_pipeline['jobs'].select { |job| job['name'].start_with? 'run-errand-shield-expe' }
        expect(generated_errand_jobs.size).to eq(2)
      end

      it 'generates a shared serial_groups for shield boshrelease errand jobs' do
        serial_groups = generated_pipeline['jobs'].select { |job| job['name'].start_with? 'run-errand-shield-expe' }.map { |job| job['serial_groups'] }.uniq.flatten
        expect(serial_groups).to eq(['auto-errand-shield-expe'])
      end
    end

    context 'when bosh-options are defined' do
      let(:shield_dependencies_only_with_manual_errands_definition_only) do
        shield_only = <<~YAML
          shield-expe:
            stemcells:
              bosh-openstack-kvm-ubuntu-xenial-go_agent:
            releases:
              cf-routing-release:
                base_location: https://bosh.io/d/github.com/
                repository: cloudfoundry-incubator/cf-routing-release
                version: 0.169.0
            manual-errands:
              manual-import:
              manual-smoke-tests:
                display-name: my-smoke-tests
            bosh-deployment:
              active: true
            status: enabled
        YAML
        YAML.safe_load(shield_only)
      end
      let(:all_dependencies) { shield_dependencies_only_with_manual_errands_definition_only }
      let(:expected_shield_manual_errand) do
        my_shield_errand_yaml = <<~YAML
          - in_parallel:
            - get: concourse-meta
              passed: [ deploy-shield-expe ]
              # Not triggered automatically as it is a manual errand
          - put: errand-shield-expe
            params:
              name: manual-smoke-tests
        YAML
        YAML.safe_load(my_shield_errand_yaml)
      end

      it 'generates an manual errand resource for shield boshrelease' do
        generated_errand_resource = generated_pipeline['resources'].select { |job| job['name'] == 'errand-shield-expe' }
        expect(generated_errand_resource).to match(expected_shield_errand_resource)
      end

      it 'generates an errand job for shield boshrelease with custom name' do
        generated_errand_job = generated_pipeline['jobs'].select { |job| job['name'] == 'run-manual-errand-shield-expe-my-smoke-tests' }.flat_map { |job| job['plan'] }
        expect(generated_errand_job).to match(expected_shield_manual_errand)
      end

      it 'generates an errand job for shield boshrelease with default name' do
        generated_errand_job = generated_pipeline['jobs'].select { |job| job['name'] == 'run-manual-errand-shield-expe-manual-import' }.flat_map { |job| job['plan'] }
        expect(generated_errand_job).not_to be_nil
      end

      it 'generates a concourse job per manual errand for shield boshrelease' do
        generated_errand_jobs = generated_pipeline['jobs'].select { |job| job['name'].start_with? 'run-manual-errand-shield-expe' }
        expect(generated_errand_jobs.size).to eq(2)
      end

      it 'generates serialized manual errand job for shield boshrelease' do
        serials = generated_pipeline['jobs'].select { |job| job['name'].start_with? 'run-manual-errand-shield-expe' }.map { |job| job['serial'] }.uniq.flatten
        expect(serials).to be_truthy
      end
    end

    context 'when git-options are defined' do
      let(:shield_dependencies_with_git_options) do
        shield_only = <<~YAML
          custom-shield:
            stemcells:
              bosh-openstack-kvm-ubuntu-xenial-go_agent:
            releases:
              cf-routing-release:
                base_location: https://bosh.io/d/github.com/
                repository: cloudfoundry-incubator/cf-routing-release
                version: 0.169.0
            git-options:
              submodule_recursive: true
              depth: 1024
            bosh-deployment:
              active: true
            status: enabled
          default-shield:
            stemcells:
              bosh-openstack-kvm-ubuntu-xenial-go_agent:
            releases:
              cf-routing-release:
                base_location: https://bosh.io/d/github.com/
                repository: cloudfoundry-incubator/cf-routing-release
                version: 0.169.0
            bosh-deployment:
              active: true
            status: enabled

        YAML
        YAML.safe_load(shield_only)
      end
      let(:all_dependencies) { shield_dependencies_with_git_options }
      let(:expected_custom_shield_resource_definition) do
        my_shield_yaml = <<~YAML
          - get: paas-templates-custom-shield
            trigger: true
            params:
              submodules: none
              submodule_recursive: 'true'
              depth: 1024
        YAML
        YAML.safe_load(my_shield_yaml)
      end
      let(:expected_default_shield_resource_definition) do
        my_shield_yaml = <<~YAML
          - get: paas-templates-default-shield
            trigger: true
            params:
              submodules: none
              submodule_recursive: "false"
              depth: 0
        YAML
        YAML.safe_load(my_shield_yaml)
      end


      it 'generates default get step for paas-templates' do
        generated_errand_job = generated_pipeline['jobs'].select { |job| job['name'] == 'deploy-default-shield' }
                                   .flat_map { |job| job['plan'] }
                                   .flat_map { |job| job['in_parallel'] }.compact
                                   .select { |step| step['get'] == 'paas-templates-default-shield' }
        expect(generated_errand_job).to match(expected_default_shield_resource_definition)
      end

      it 'generates customized get step forpaas-templates' do
        generated_errand_job = generated_pipeline['jobs'].select { |job| job['name'] == 'deploy-custom-shield' }
                                   .flat_map { |job| job['plan'] }
                                   .flat_map { |job| job['in_parallel'] }.compact
                                   .select { |step| step['get'] == 'paas-templates-custom-shield' }
        expect(generated_errand_job).to match(expected_custom_shield_resource_definition)
      end
    end

    context 'when an manual errand job is defined' do
      let(:shield_dependencies_only_with_manual_errands_definition_only) do
        shield_only = <<~YAML
          shield-expe:
            stemcells:
              bosh-openstack-kvm-ubuntu-xenial-go_agent:
            releases:
              cf-routing-release:
                base_location: https://bosh.io/d/github.com/
                repository: cloudfoundry-incubator/cf-routing-release
                version: 0.169.0
            manual-errands:
              manual-import:
              manual-smoke-tests:
                display-name: my-smoke-tests
            bosh-deployment:
              active: true
            status: enabled
        YAML
        YAML.safe_load(shield_only)
      end
      let(:all_dependencies) { shield_dependencies_only_with_manual_errands_definition_only }
      let(:expected_shield_manual_errand) do
        my_shield_errand_yaml = <<~YAML
          - in_parallel:
            - get: concourse-meta
              passed: [ deploy-shield-expe ]
              # Not triggered automatically as it is a manual errand
          - put: errand-shield-expe
            params:
              name: manual-smoke-tests
        YAML
        YAML.safe_load(my_shield_errand_yaml)
      end

      it 'generates an manual errand resource for shield boshrelease' do
        generated_errand_resource = generated_pipeline['resources'].select { |job| job['name'] == 'errand-shield-expe' }
        expect(generated_errand_resource).to match(expected_shield_errand_resource)
      end

      it 'generates an errand job for shield boshrelease with custom name' do
        generated_errand_job = generated_pipeline['jobs'].select { |job| job['name'] == 'run-manual-errand-shield-expe-my-smoke-tests' }.flat_map { |job| job['plan'] }
        expect(generated_errand_job).to match(expected_shield_manual_errand)
      end

      it 'generates an errand job for shield boshrelease with default name' do
        generated_errand_job = generated_pipeline['jobs'].select { |job| job['name'] == 'run-manual-errand-shield-expe-manual-import' }.flat_map { |job| job['plan'] }
        expect(generated_errand_job).not_to be_nil
      end

      it 'generates a concourse job per manual errand for shield boshrelease' do
        generated_errand_jobs = generated_pipeline['jobs'].select { |job| job['name'].start_with? 'run-manual-errand-shield-expe' }
        expect(generated_errand_jobs.size).to eq(2)
      end

      it 'generates serialized manual errand job for shield boshrelease' do
        serials = generated_pipeline['jobs'].select { |job| job['name'].start_with? 'run-manual-errand-shield-expe' }.map { |job| job['serial'] }.uniq.flatten
        expect(serials).to be_truthy
      end
    end

    context 'without ci deployment overview' do
      it 'processes only one template' do
        expect(@processed_template.length).to eq(1)
      end

      it 'processes is not empty' do
        expect(@processed_template).not_to be_empty
      end

      it 'generates a valid yaml file' do
        expect(generated_pipeline).not_to be_falsey
      end

      it 'generates all resource_types' do
        expect(generated_pipeline['resource_types']).to match(expected_resource_types)
      end

      it 'generates all groups' do
        expect(generated_pipeline['groups']).to match(groups)
      end

      it 'generates a group using root deployment name ' do
        generated_group = generated_pipeline['groups'].select { |concourse_group| concourse_group['name'] == root_deployment_name.downcase }
        expect(generated_group).not_to be_empty
      end
    end

    context 'when boshrelease offline mode is enabled with precompilation' do
      let(:expected_boshreleases) do
        { 'cf-routing-release' => 'cloudfoundry-incubator',
          'route-registrar-boshrelease' => 'cloudfoundry-community',
          'haproxy-boshrelease' => 'cloudfoundry-community' }
      end
      let(:expected_s3_precompiled_boshreleases) do
        expected_boshreleases.map do |br_name, br_repo|
          fragment = <<~YAML
            - name: #{br_name}
              icon: home-floor-b
              type: s3
              source:
                bucket: ((s3-compiled-release-bucket))
                region_name: ((s3-compiled-release-region-name))
                regexp: #{br_repo}/#{br_name}-(.*)-(.*)-(.*)-((stemcell.version)).tgz
                access_key_id: ((s3-compiled-release-access-key-id))
                secret_access_key: ((s3-compiled-release-secret-key))
                endpoint: ((s3-compiled-release-endpoint))
                skip_ssl_verification: ((s3-compiled-release-skip-ssl-verification))
                skip_download: true
              version:
                path: "#{br_repo}/#{br_name}-((releases.#{br_name}.version))-((s3-compiled-release-os))-((stemcell.version)).tgz"
          YAML
          YAML.safe_load fragment
        end.flatten
      end
      let(:expected_boshrelease_put_version) do
        expected_boshreleases.flat_map { |name, _repo| { name => "#{name}/*.tgz" } }
      end
      let(:expected_s3_deployment_put) do
        expected_yaml = <<~YAML
          - bui-deployment:
            - #{expected_boshrelease_put_version.flat_map { |br| br['haproxy-boshrelease'] }.compact.first}
            - #{expected_boshrelease_put_version.flat_map { |br| br['route-registrar-boshrelease'] }.compact.first}
          - shield-expe-deployment:
            - #{expected_boshrelease_put_version.flat_map { |br| br['cf-routing-release'] }.compact.first}
        YAML
        YAML.safe_load expected_yaml
      end
      let(:expected_push_stemcell_tasks) { %w[upload-stemcells] }
      let(:expected_push_boshreleases_tasks) { %w[reformat-root-deployment-yml missing-s3-boshreleases repackage-releases repackage-releases-fallback upload-repackaged-releases check-repackaging-errors] }
      it 'generates s3 precompiled bosh release resource' do
        s3_boshreleases = generated_pipeline['resources'].select { |resource| resource['type'] == 's3' && resource['name'] != "((stemcell-main-name))" }
        expect(s3_boshreleases).to include(*expected_s3_precompiled_boshreleases)
      end

      it 'does not generate s3 version using path on get' do
        boshrelease_get_version = generated_pipeline['jobs'].flat_map { |job| job['plan'] }
          .flat_map { |plan| plan['in_parallel'] }
          .compact
          .select { |resource| expected_boshreleases.key?(resource['get']) }
          .flat_map { |resource| { resource['get'] => resource['version'] } }
        expect(boshrelease_get_version).to all(satisfy { |_k, v| v.nil? })
      end

      it 'generates push-stemcells tasks' do
        push_stemcell_job_tasks = generated_pipeline['jobs']
                                      .select { |job| job['name'] == "push-stemcell" }
                                      .flat_map { |job| job['plan'] }
                                      .flat_map { |step| step['task'] }.compact
        expect(push_stemcell_job_tasks).to match(expected_push_stemcell_tasks)
      end

      it 'generates push-boshreleases tasks' do
        push_boshreleases_job_tasks = generated_pipeline['jobs']
                                      .select { |job| job['name'] == "push-boshreleases" }
                                      .flat_map { |job| job['plan'] }
                                      .flat_map { |step| step['task'] }.compact
        expect(push_boshreleases_job_tasks).to match(expected_push_boshreleases_tasks)
      end


      it 'generates init-concourse-boshrelease-and-stemcell-for-ops-depls' do
        expected_init_version = expected_boshreleases.values.flat_map { |get_version| "path:#{get_version}" }
        init_args = generated_pipeline['jobs']
          .select { |job| job['name'] == "init-concourse-boshrelease-and-stemcell-for-#{root_deployment_name}" }
          .flat_map { |job| job['plan'] }
          .select { |step| step['task'] && step['task'] == "generate-#{root_deployment_name}-flight-plan" }
          .flat_map { |task| task['config']['run']['args'] }
        expect(init_args[1]).to include(*expected_init_version)
      end
    end


    context 'when precompile mode is disabled with offline boshreleases' do
      let(:loaded_config) do
        my_config_yaml = <<~YAML
          offline-mode:
            stemcells: true
            boshreleases: true
          precompile-mode: false
        YAML
        YAML.safe_load(my_config_yaml)
      end
      let(:expected_boshreleases) do
        { 'cf-routing-release' => 'cloudfoundry-incubator',
          'route-registrar-boshrelease' => 'cloudfoundry-community',
          'haproxy-boshrelease' => 'cloudfoundry-community' }
      end
      let(:expected_s3_boshreleases) do
        expected_boshreleases.map do |br_name, br_repo|
          fragment = <<~YAML
            - name: #{br_name}
              icon: home-floor-a
              type: s3
              source:
                bucket: ((s3-br-bucket))
                region_name: ((s3-br-region-name))
                regexp: #{br_repo}/#{br_name}-(.*).tgz
                access_key_id: ((s3-br-access-key-id))
                secret_access_key: ((s3-br-secret-key))
                endpoint: ((s3-br-endpoint))
                skip_ssl_verification: ((s3-br-skip-ssl-verification))
                skip_download: true
              version:
                path: "#{br_repo}/#{br_name}-((releases.#{br_name}.version)).tgz"
          YAML
          YAML.safe_load fragment
        end.flatten
      end

      it 'generates s3 bosh release resource' do
        s3_boshreleases = generated_pipeline['resources'].select { |resource| resource['type'] == 's3' && resource['name'] != "((stemcell-main-name))" }
        expect(s3_boshreleases).to include(*expected_s3_boshreleases)
      end
    end

    context 'when precompile mode is disabled without offline boshreleases' do
      let(:loaded_config) do
        my_config_yaml = <<~YAML
          offline-mode:
            stemcells: true
          precompile-mode: false
        YAML
        YAML.safe_load(my_config_yaml)
      end
      let(:expected_bosh_io_stemcell) do
        expected_yaml = <<~YAML
          - name: ((stemcell-main-name))
            icon: home-floor-l
            type: s3
            source:
              access_key_id: ((s3-stemcell-access-key-id))
              bucket: ((s3-stemcell-bucket))
              endpoint: ((s3-stemcell-endpoint))
              regexp: ((stemcell-name-prefix))((stemcell-main-name))/bosh-stemcell-(.*)-((stemcell-main-name)).tgz
              region_name: ((s3-stemcell-region-name))
              secret_access_key: ((s3-stemcell-secret-key))
              skip_download: true
              skip_ssl_verification: ((s3-stemcell-skip-ssl-verification))
            version:
              path: ((stemcell-name-prefix))((stemcell-main-name))/bosh-stemcell-((stemcell.version))-((stemcell-main-name)).tgz
        YAML
        YAML.safe_load expected_yaml
      end

      let(:expected_push_stemcell_tasks) { %w[upload-stemcells download-stemcell upload-to-director] }
      let(:expected_push_boshreleases_tasks) { %w[repackage-releases repackage-releases-fallback upload-to-director check-repackaging-errors] }
      let(:expected_stemcell_init) { 'echo "check-resource -r $BUILD_PIPELINE_NAME/((stemcell-main-name)) --from path:((stemcell-name-prefix))((stemcell-main-name))/bosh-stemcell-((stemcell.version))-((stemcell-main-name)).tgz' }

      it 'generates bosh-io stemcell with pinned version' do
        bosh_io_stemcell = generated_pipeline['resources'].select { |resource| resource['name'] == '((stemcell-main-name))' }
        expect(bosh_io_stemcell).to eq(expected_bosh_io_stemcell)
      end

      it 'generates bosh_io version using path on get' do
        stemcell_get_step = generated_pipeline['jobs']
                                .select { |job| job['name'] == "push-stemcell" }
                                .flat_map { |job| job['plan'] }
                                .flat_map { |plan| plan['in_parallel'] }
                                .compact
                                .select { |resource| resource['get'] == '((stemcell-main-name))' }
        expect(stemcell_get_step).to be_empty
      end

      it 'generates push-stemcell with stemcell upload to director' do
        push_stemcell_job_tasks = generated_pipeline['jobs']
                          .select { |job| job['name'] == "push-stemcell" }
                          .flat_map { |job| job['plan'] }
                          .flat_map { |step| step['task'] }.compact
        expect(push_stemcell_job_tasks).to match(expected_push_stemcell_tasks)
      end

      it 'generates push-boshreleases tasks' do
        push_boshreleases_job_tasks = generated_pipeline['jobs']
                                          .select { |job| job['name'] == "push-boshreleases" }
                                          .flat_map { |job| job['plan'] }
                                          .flat_map { |step| step['task'] }.compact
        expect(push_boshreleases_job_tasks).to match(expected_push_boshreleases_tasks)
      end

      it 'generates init-concourse-boshrelease-and-stemcell-for-ops-depls' do
        init_args = generated_pipeline['jobs']
                        .select { |job| job['name'] == "init-concourse-boshrelease-and-stemcell-for-#{root_deployment_name}" }
                        .flat_map { |job| job['plan'] }
                        .select { |step| step['task'] && step['task'] == "generate-#{root_deployment_name}-flight-plan" }
                        .flat_map { |task| task['config']['run']['args'] }
        expect(init_args[1]).to include(*expected_stemcell_init)
      end
    end

    context 'when stemcell offline mode is disabled' do
      let(:loaded_config) do
        my_config_yaml = <<~YAML
          offline-mode:
            boshreleases: false
            stemcells: false
            docker-images: false
        YAML
        YAML.safe_load(my_config_yaml)
      end
      let(:expected_bosh_io_stemcell) do
        expected_yaml = <<~YAML
          - name: ((stemcell-main-name))
            icon: home-floor-g
            type: bosh-io-stemcell
            source:
              name: ((stemcell-name-prefix))((stemcell-main-name))
            version:
              version: ((stemcell.version))
        YAML
        YAML.safe_load expected_yaml
      end
      let(:expected_stemcell_upload_task) do
        [{ "task"=>"download-stemcell",
           "attempts"=>2,
           "file"=>"cf-ops-automation/concourse/tasks/download_stemcell/task.yml",
           "output_mapping"=>{"stemcell"=>"((stemcell-main-name))"},
           "params"=>
                 {"STEMCELL_BASE_LOCATION"=>"https://bosh.io/d/stemcells",
                       "STEMCELL_MAIN_NAME"=>"((stemcell-main-name))",
                       "STEMCELL_PREFIX"=>"((stemcell-name-prefix))",
                       "STEMCELL_VERSION"=>"((stemcell.version))"},
          },
          {"task"=>"upload-to-director",
          "file"=>"cf-ops-automation/concourse/tasks/bosh_upload_stemcell/task.yml",
          "input_mapping"=> {"config-resource"=>"secrets-my-root-depls-limited", "stemcell"=>"((stemcell-main-name))"},
          "attempts" => 2,
          "params"=>
             {"BOSH_CA_CERT"=> "config-resource/shared/certs/internal_paas-ca/server-ca.crt",
              "BOSH_CLIENT"=>"((bosh-username))",
              "BOSH_CLIENT_SECRET"=>"((bosh-password))",
              "BOSH_ENVIRONMENT"=>"((bosh-target))"}
        }]
      end
      let(:expected_stemcell_init) { 'echo "check-resource -r $BUILD_PIPELINE_NAME/((stemcell-main-name)) --from version:((stemcell.version))" | tee -a result-dir/flight-plan' }

      it 'generates bosh-io stemcell with pinned version' do
        bosh_io_stemcell = generated_pipeline['resources'].select { |resource| resource['type'] == 'bosh-io-stemcell' }
        expect(bosh_io_stemcell).to eq(expected_bosh_io_stemcell)
      end

      it 'generates bosh_io version using path on get' do
        stemcell_get_step = generated_pipeline['jobs']
          .select { |job| job['name'] == "push-stemcell" }
          .flat_map { |job| job['plan'] }
          .flat_map { |plan| plan['in_parallel'] }
          .compact
          .select { |resource| resource['get'] == '((stemcell-main-name))' }
        expect(stemcell_get_step).to be_empty
      end

      it 'generates push-stemcell with stemcell upload to director' do
        upload_task = generated_pipeline['jobs']
          .select { |job| job['name'] == "push-stemcell" }
          .flat_map { |job| job['plan'] }
          .select { |step| step['task'] }
        expect(upload_task).to match(expected_stemcell_upload_task)
      end

      it 'generates init-concourse-boshrelease-and-stemcell-for-ops-depls' do
        init_args = generated_pipeline['jobs']
          .select { |job| job['name'] == "init-concourse-boshrelease-and-stemcell-for-#{root_deployment_name}" }
          .flat_map { |job| job['plan'] }
          .select { |step| step['task'] && step['task'] == "generate-#{root_deployment_name}-flight-plan" }
          .flat_map { |task| task['config']['run']['args'] }
        expect(init_args[1]).to include(*expected_stemcell_init)
      end
    end

    context 'with ci deployment overview without terraform' do
      let(:all_ci_deployments) do
        ci_deployments_yaml = <<~YAML
          #{root_deployment_name}:
            target_name: my-concourse-name
            pipelines:
              #{root_deployment_name}-bosh-generated:
                team: #{custom_team}
              #{root_deployment_name}-cf-apps-generated:
        YAML
        YAML.safe_load ci_deployments_yaml
      end
      let(:custom_team) { 'my-custom-team' }
      let(:fly_into_concourse_context) do
        { depls: root_deployment_name,
          team: custom_team }
      end
      let(:expected_fly_into_concourse) do
        Coa::TestFixtures.expand_task_params_template('fly-into-concourse', fly_into_concourse_context)
      end

      it 'generates all resource_types' do
        expect(generated_pipeline['resource_types']).to match_array(expected_resource_types)
      end

      it 'generates all groups' do
        groups.select { |item| %w[Utils My-root-depls].include?(item['name']) }.each do |item|
          item['jobs'].sort!
        end
        expect(generated_pipeline['groups']).to match_array(groups)
      end

      it 'generates retrigger all and init boshrelease version' do
        fly_into_concourse_params = generated_pipeline['jobs']
          .flat_map { |job| job['plan'] }
          .select { |step| step['task']&.start_with?("fly-into-concourse") }
          .flat_map { |step| step['params'] }

        fly_into_concourse_params.each { |task_params| expect(task_params).to match(expected_fly_into_concourse) }
      end
    end

    context 'when terraform is enabled ' do
      let(:all_ci_deployments) do
        ci_deployments_yaml = <<~YAML
          #{root_deployment_name}:
            terraform_config:
              state_file_path: my-tfstate-location
            target_name: my-concourse-name
            pipelines:
              #{root_deployment_name}-bosh-generated:
              #{root_deployment_name}-cf-apps-generated:
        YAML
        YAML.safe_load ci_deployments_yaml
      end
      let(:expected_tf_ensure_step) do
        {"file" => "cf-ops-automation/concourse/tasks/git_update_a_file_from_generated.yml",
         "input_mapping" => { "generated-resource" => "terraform-cf", "reference-resource" => "secrets-full-writer" },
         "on_failure" => { "params" => { "channel" => "((slack-channel))", "icon_url" => "http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png", "text" => "Failure during [[$BUILD_PIPELINE_NAME/$BUILD_JOB_NAME]($ATC_EXTERNAL_URL/teams/$BUILD_TEAM_NAME/pipelines/$BUILD_PIPELINE_NAME/jobs/$BUILD_JOB_NAME/builds/$BUILD_NAME)].", "username" => "Concourse" }, "put" => "failure-alert" },
         "on_success" => { "get_params" => { "depth" => 0, "submodules" => "none" }, "params" => { "rebase" => true, "repository" => "updated-terraform-state-secrets" }, "put" => "secrets-full-writer" },
         "output_mapping" => { "updated-git-resource" => "updated-terraform-state-secrets" },
         "params" => { "COMMIT_MESSAGE" => "Terraform TFState auto update\n\nActive profiles: ${PROFILES}", "NEW_FILE" => "terraform.tfstate", "OLD_FILE" => "my-tfstate-location/terraform.tfstate", "PROFILES" => "((profiles))" },
         "task" => "update-terraform-state-file" }
      end

      it 'generates all resource_types' do
        expect(generated_pipeline['resource_types']).to match(expected_resource_types)
      end

      it 'generates terraform group' do
        expected_tf_group = { 'name' => 'terraform',
                              'jobs' => %w[approve-and-enforce-terraform-consistency check-terraform-consistency] }
        generated = generated_pipeline['groups'].select { |group| group['name'] == 'terraform' }.pop
        expect(generated).to match(expected_tf_group)
      end

      it 'ensures tfstate is commited' do
        terraform_apply_task = generated_pipeline['jobs']
                        .select { |job| job['name'] == "approve-and-enforce-terraform-consistency" }
                        .flat_map { |job| job['plan'] }
                        .select { |step| step['task'] == "terraform-apply" }
                        .first
        ensure_definition = terraform_apply_task['ensure']
        expect(ensure_definition).to match(expected_tf_ensure_step)

      end

      it 'generates a valid check-terraform-consistency job' do
        expected_tf_job =
          [
            { "task" => 'generate-terraform-tfvars',
              "input_mapping" =>
                { "scripts-resource" => "cf-ops-automation", "credentials-resource" => "secrets-my-root-depls-limited", "additional-resource" => "paas-templates-my-root-depls" },
              "output_mapping" => { "generated-files" => "terraform-tfvars" },
              "file" => "cf-ops-automation/concourse/tasks/generate_manifest/task.yml",
              "params" =>
             { "YML_FILES" =>
               "./credentials-resource/shared/secrets.yml\n./credentials-resource/my-tfstate-location/secrets/meta.yml\n./credentials-resource/my-tfstate-location/secrets/secrets.yml\n./additional-resource/meta-inf.yml\n",
               "YML_TEMPLATE_DIR" => "additional-resource/my-tfstate-location/template",
               "CUSTOM_SCRIPT_DIR" => "additional-resource/my-tfstate-location/template",
               "SUFFIX" => "-tpl.tfvars.yml",
               "IAAS_TYPE" => "((iaas-type))",
               "PROFILES" => "((profiles))" } },
            { "task" => "terraform-plan",
              "input_mapping" =>
                { "secret-state-resource" => "secrets-my-root-depls-limited",
                  "spec-resource" => "paas-templates-my-root-depls" },
              "file" => "cf-ops-automation/concourse/tasks/terraform_plan_cloudfoundry.yml",
              "params" =>
                { "SPEC_PATH" => "my-tfstate-location/spec",
                  "SECRET_STATE_FILE_PATH" => "my-tfstate-location",
                  "IAAS_SPEC_PATH" => "my-tfstate-location/spec-((iaas-type))",
                  "PROFILES" => "((profiles))",
                  "PROFILES_SPEC_PATH_PREFIX" => "my-tfstate-location/spec-" } }
          ]

        generated = generated_pipeline['jobs']
          .select { |job| job['name'] == "check-terraform-consistency" }
          .flat_map { |job| job['plan'] }
          .select { |step| step['task'] }

        expect(generated).to match(expected_tf_job)
      end
    end

    context 'when validating terraform triggering' do
      let(:check_terraform_jobs) { generated_pipeline['jobs'].select { |resource| resource['name'].start_with?('check-terraform-consistency') } }
      let(:check_terraform_plans) { check_terraform_jobs.flat_map { |job| job['plan'] } }
      let(:check_terraform_in_parallel) { check_terraform_plans.flat_map { |tasks| tasks['in_parallel'] }.compact }
      let(:check_terraform_secrets_triggering) { check_terraform_in_parallel.select { |task| task['get']&.start_with?('secrets-') }.flat_map { |task| task['trigger'] } }
      let(:check_terraform_paas_templates_triggering) { check_terraform_in_parallel.select { |task| task['get']&.start_with?('paas-templates-') }.flat_map { |task| task['trigger'] } }
      let(:enforce_terraform_jobs) { generated_pipeline['jobs'].select { |resource| resource['name'].start_with?('approve-and-enforce-terraform-consistency') } }
      let(:enforce_terraform_plans) { enforce_terraform_jobs.flat_map { |job| job['plan'] } }
      let(:enforce_terraform_in_parallel) { enforce_terraform_plans.flat_map { |tasks| tasks['in_parallel'] }.compact }
      let(:enforce_terraform_all_secrets_triggering) { enforce_terraform_in_parallel.select { |task| task['get']&.start_with?('secrets-') }.flat_map { |task| task['trigger'] } }
      let(:enforce_terraform_paas_templates_triggering) { enforce_terraform_in_parallel.select { |task| task['get']&.start_with?('paas-templates-') }.flat_map { |task| task['trigger'] } }
      let(:all_ci_deployments) { enable_root_deployment_terraform }

      it 'triggers check-consistency automatically on each commit on secrets' do
        expect(check_terraform_secrets_triggering.uniq).to match([true])
      end

      it 'triggers check-consistency automatically on each commit on paas-templates' do
        expect(check_terraform_paas_templates_triggering.uniq).to match([true])
      end

      it 'triggers approve-and-enforce manually on secrets' do
        expect(enforce_terraform_all_secrets_triggering).to match([nil, nil])
      end

      it 'triggers approve-and-enforce manually on paas-templates' do
        expect(enforce_terraform_paas_templates_triggering.uniq).to match([false]).or match([nil])
      end
    end
  end

  context 'when a boshrelease overrides with another value' do
    subject { TemplateProcessor.new root_deployment_name, config, processor_context }

    let(:all_dependencies) do
      deps_yaml = <<~YAML
        shield-expe:
          stemcells:
            bosh-openstack-kvm-ubuntu-xenial-go_agent:
          releases:
            cf-routing-release:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry-incubator/cf-routing-release
              version: 0.169.0
          bosh-deployment:
            active: true
          status: enabled
        bui:
          stemcells:
            bosh-openstack-kvm-ubuntu-xenial-go_agent:
          releases:
            cf-routing-release:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry-community/route-registrar-boshrelease
              version: '3'
            haproxy-boshrelease:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry-community/haproxy-boshrelease
              version: 8.0.12
          bosh-deployment:
            active: true
          status: enabled
      YAML
      YAML.safe_load(deps_yaml)
    end
    let(:template_processing_error) { subject.process(@pipelines_dir + '/*') }

    before(:context) do
      @output_dir = Dir.mktmpdir('generated-pipelines')
      @pipelines_output_dir = File.join(@output_dir, 'pipelines')
      @template_pipeline_name = 'bosh-pipeline.yml.erb'
      @pipelines_dir = Dir.mktmpdir('pipeline-templates')

      FileUtils.copy("concourse/pipelines/template/#{@template_pipeline_name}", @pipelines_dir)
    end

    it 'raises an error' do
      expect { template_processing_error }.to raise_error(RuntimeError, /Inconsitency detected with 'cf-routing-release' boshrelease, in 'shield-expe' deployment: trying to replace.*/)
    end
  end
end
