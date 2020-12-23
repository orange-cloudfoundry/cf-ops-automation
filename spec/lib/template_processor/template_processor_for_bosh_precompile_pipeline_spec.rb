require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'template_processor'
require 'ci_deployment'
require 'deployment_deployers_config'
require 'pipeline_generator'
require_relative 'test_fixtures'

describe 'BoshPrecompilePipelineTemplateProcessing' do
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
        stemcells:
          bosh-openstack-kvm-ubuntu-xenial-go_agent:
        bosh-deployment: {}
        releases:
          bosh:
            base_location: https://github.com/
            repository: cloudfoundry/bosh
            version: 271.0.0
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
      precompile:
        skip-upload: false
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
    YAML
    YAML.safe_load(resource_types_yaml)
  end
  let(:groups) do
    [
      { 'name' => 'my-root-depls',
        'jobs' =>
         %w[compile-and-export-bosh
            compile-and-export-cf-routing-release
            compile-and-export-haproxy-boshrelease
            compile-and-export-route-registrar-boshrelease
            init-concourse-boshrelease-and-stemcell-for-my-root-depls
            push-boshreleases
            push-stemcell
            upload-compiled-bosh
            upload-compiled-cf-routing-release
            upload-compiled-haproxy-boshrelease
            upload-compiled-route-registrar-boshrelease] },
      { 'name' => 'utils', 'jobs' => %w[init-concourse-boshrelease-and-stemcell-for-my-root-depls push-boshreleases push-stemcell] },
      { "name" => "compiled-releases", "jobs" => %w[upload-compiled-bosh upload-compiled-cf-routing-release upload-compiled-haproxy-boshrelease upload-compiled-route-registrar-boshrelease] },
      { "name" => "releases", "jobs" => %w[compile-and-export-bosh compile-and-export-cf-routing-release compile-and-export-haproxy-boshrelease compile-and-export-route-registrar-boshrelease] },
      { "name" => "b", "jobs" => %w[compile-and-export-bosh upload-compiled-bosh] },
      { "name" => "c", "jobs" => %w[compile-and-export-cf-routing-release upload-compiled-cf-routing-release] },
      { "name" => "h", "jobs" => %w[compile-and-export-haproxy-boshrelease upload-compiled-haproxy-boshrelease] },
      { "name" => "r", "jobs" => %w[compile-and-export-route-registrar-boshrelease upload-compiled-route-registrar-boshrelease] }
    ]
  end
  let(:enable_root_deployment_terraform) do
    ci_deployments_yaml = <<~YAML
      #{root_deployment_name}:
        terraform_config:
          state_file_path: my-tfstate-location
        target_name: my-concourse-name
        pipelines:
          #{root_deployment_name}-bosh-precompile-generated:
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

  context 'when processing bosh-precompile-pipeline.yml.erb' do
    subject { TemplateProcessor.new root_deployment_name, config, processor_context }

    before(:context) do
      @output_dir = Dir.mktmpdir('generated-pipelines')
      @pipelines_output_dir = File.join(@output_dir, 'pipelines')
      @template_pipeline_name = 'bosh-precompile-pipeline.yml.erb'
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

    context 'when disabled deployments are presents' do
      let(:expected_compiled_exported_deployments) { %W[compile-and-export-bosh compile-and-export-route-registrar-boshrelease compile-and-export-haproxy-boshrelease compile-and-export-cf-routing-release] }
      let(:expected_uploaded_deployments) { %W[upload-compiled-bosh upload-compiled-route-registrar-boshrelease upload-compiled-haproxy-boshrelease upload-compiled-cf-routing-release] }

      it 'generates compile and export job for dependencies describe in disabled deployments' do
        filtered_generated_jobs = generated_pipeline['jobs'].select { |job| job['name']&.start_with?('compile-and-export') }.flat_map { |job| job['name'] }
        expect(filtered_generated_jobs).to match(expected_compiled_exported_deployments)
      end

      it 'generates upload job for dependencies describe in disabled deployments' do
        filtered_generated_jobs = generated_pipeline['jobs'].select { |job| job['name']&.start_with?('upload-compiled') }.flat_map { |job| job['name'] }
        expect(filtered_generated_jobs).to match(expected_uploaded_deployments)
      end
    end

    context 'when deployments are excluded' do
      let(:expected_compiled_exported_deployments) { %W[compile-and-export-bosh compile-and-export-route-registrar-boshrelease compile-and-export-haproxy-boshrelease compile-and-export-cf-routing-release] }
      let(:expected_uploaded_deployments) { %W[upload-compiled-bosh upload-compiled-route-registrar-boshrelease upload-compiled-haproxy-boshrelease upload-compiled-cf-routing-release] }
      let(:loaded_config) do
        my_config_yaml = <<~YAML
          offline-mode:
            boshreleases: true
            stemcells: true
            docker-images: false

          #{root_deployment_name}:
            precompile:
              excluded_deployments:
                - bui
        YAML
        YAML.safe_load(my_config_yaml)
      end

      it 'generates compile jobs only for non excluded deployments' do
        filtered_generated_jobs = generated_pipeline['jobs'].select { |job| job['name']&.start_with?('compile-and-export') }.flat_map { |job| job['name'] }
        expect(filtered_generated_jobs).to match(expected_compiled_exported_deployments)
      end

      it 'does not generate upload jobs' do
        filtered_generated_jobs = generated_pipeline['jobs'].select { |job| job['name']&.start_with?('upload-compiled') }.flat_map { |job| job['name'] }
        expect(filtered_generated_jobs).to be_empty
      end

      it 'generates all groups' do
        expect(generated_pipeline['groups'].flat_map { |group| group['name'] }.sort).to match(groups.flat_map { |group| group['name'] }.reject{ |group_name| group_name.start_with?('compiled-releases')}.sort)
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
        expect(generated_pipeline['groups'].flat_map { |group| group['name'] }.sort).to match(groups.flat_map { |group| group['name'] }.sort)
      end

      it 'generates a group using root deployment name ' do
        generated_group = generated_pipeline['groups'].select { |concourse_group| concourse_group['name'] == root_deployment_name.downcase }
        expect(generated_group).not_to be_empty
      end
    end

    context 'when offline boshrelease mode is enabled with precompilation' do
      let(:loaded_config) do
        my_config_yaml = <<~YAML
          offline-mode:
            boshreleases: true
            stemcells: true
            docker-images: false
        YAML
        YAML.safe_load(my_config_yaml)
      end
      let(:expected_boshreleases) do
        { 'bosh' => 'cloudfoundry',
          'cf-routing-release' => 'cloudfoundry-incubator',
          'route-registrar-boshrelease' => 'cloudfoundry-community',
          'haproxy-boshrelease' => 'cloudfoundry-community' }
      end
      let(:expected_s3_precompiled_boshreleases) do
        expected_boshreleases.map do |br_name, br_repo|
          fragment = <<~YAML
            - name: compiled-#{br_name}
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
              version:
                path: "#{br_repo}/#{br_name}-((releases.#{br_name}.version))-((s3-compiled-release-os))-((stemcell.version)).tgz"
          YAML
          YAML.safe_load fragment
        end.flatten
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
              version:
                path: "#{br_repo}/#{br_name}-((releases.#{br_name}.version)).tgz"
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
      let(:expected_push_boshreleases_tasks) { %w[reformat-root-deployment-yml missing-s3-boshreleases repackage-releases repackage-releases-fallback upload-repackaged-releases upload-to-director check-repackaging-errors] }

      it 'generates s3 precompiled resources (ie use precompile bucket)' do
        s3_precompiled_boshreleases = generated_pipeline['resources'].select { |resource| resource['type'] == 's3' && resource['name'].start_with?('compiled-') }
        expect(s3_precompiled_boshreleases).to include(*expected_s3_precompiled_boshreleases)
      end

      it 'generates s3 bosh release resource (ie use br bucket) ' do
        s3_boshreleases = generated_pipeline['resources'].select { |resource| resource['type'] == 's3' && !resource['name'].start_with?('compiled-') && resource['name'] != "((stemcell-main-name))" }
        expect(s3_boshreleases).to include(*expected_s3_boshreleases)
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



    context 'when online boshreleases and offline stemcells are used' do
      let(:loaded_config) do
        my_config_yaml = <<~YAML
          offline-mode:
            stemcells: true
          precompile-mode: false
          precompile:
            skip-upload: false
        YAML
        YAML.safe_load(my_config_yaml)
      end
      let(:expected_s3_stemcell) do
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
              skip_ssl_verification: ((s3-stemcell-skip-ssl-verification))
            version:
              path: ((stemcell-name-prefix))((stemcell-main-name))/bosh-stemcell-((stemcell.version))-((stemcell-main-name)).tgz
        YAML
        YAML.safe_load expected_yaml
      end

      let(:expected_push_stemcell_tasks) { %w[upload-stemcells] }
      let(:expected_push_boshreleases_tasks) { %w[repackage-releases repackage-releases-fallback upload-to-director check-repackaging-errors] }
      let(:expected_stemcell_init) { 'echo "check-resource -r $BUILD_PIPELINE_NAME/((stemcell-main-name)) --from path:((stemcell-name-prefix))((stemcell-main-name))/bosh-stemcell-((stemcell.version))-((stemcell-main-name)).tgz' }

      it 'generates s3 stemcell with pinned version' do
        bosh_io_stemcell = generated_pipeline['resources'].select { |resource| resource['name'] == '((stemcell-main-name))' }
        expect(bosh_io_stemcell).to eq(expected_s3_stemcell)
      end

      it 'generates s3 version using path on get' do
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

      it 'generates init-concourse-boshrelease-and-stemcell-for-#{root_deployment_name}' do
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
          precompile:
            skip-upload: false
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
           "input_mapping"=>{"templates-resource"=>"paas-templates-my-root-depls-limited"},
           "output_mapping"=>{"stemcell"=>"((stemcell-main-name))"},
           "params"=>
                 {"STEMCELL_BASE_LOCATION"=>"https://bosh.io/d/stemcells",
                       "STEMCELL_MAIN_NAME"=>"((stemcell-main-name))",
                       "STEMCELL_PREFIX"=>"((stemcell-name-prefix))",
                  "VERSIONS_FILE"=>"templates-resource/my-root-depls/root-deployment.yml"}
          },
         {"task"=>"upload-to-director",
         "file"=>"cf-ops-automation/concourse/tasks/bosh_upload_stemcell/task.yml",
         "input_mapping"=> {"config-resource"=>"secrets-full-writer", "stemcell"=>"((stemcell-main-name))"},
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
              #{root_deployment_name}-bosh-precompile-generated:
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
      @template_pipeline_name = 'bosh-precompile-pipeline.yml.erb'
      @pipelines_dir = Dir.mktmpdir('pipeline-templates')

      FileUtils.copy("concourse/pipelines/template/#{@template_pipeline_name}", @pipelines_dir)
    end

    it 'raises an error' do
      expect { template_processing_error }.to raise_error(RuntimeError, /Inconsitency detected with 'cf-routing-release' boshrelease, in 'shield-expe' deployment: trying to replace.*/)
    end
  end
end
