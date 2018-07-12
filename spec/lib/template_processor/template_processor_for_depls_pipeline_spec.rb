require 'rspec'
require 'fileutils'
require 'tmpdir'

require 'template_processor'
require 'ci_deployment'
require 'deployment_deployers_config'
require 'pipeline_generator'

describe 'DeplsPipelineTemplateProcessing' do
  let(:root_deployment_name) { 'my-root-depls' }
  let(:bosh_cert) { BOSH_CERT_LOCATIONS = { root_deployment_name => 'shared/certificate.pem' }.freeze }
  let(:processor_context) do
    { depls: root_deployment_name,
      bosh_cert: bosh_cert,
      all_dependencies: all_dependencies,
      all_ci_deployments: all_ci_deployments,
      git_submodules: git_submodules,
      config: loaded_config }
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
          bosh-openstack-kvm-ubuntu-trusty-go_agent:
          releases:
            cf-routing-release:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry-incubator/cf-routing-release
              version: 0.169.0
          errands:
              import:
          bosh-deployment:
            active: true
          status: enabled
      bui:
          stemcells:
          bosh-openstack-kvm-ubuntu-trusty-go_agent:
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
      - name: bosh-deployment
        type: docker-image
        source:
          repository: concourse/bosh-deployment-resource
          tag: latest
      - name: slack-notification
        type: docker-image
        source:
          repository: cfcommunity/slack-notification-resource
          tag: v1.4.2
      - name: cron-resource
        type: docker-image
        source:
          repository: cftoolsmiths/cron-resource
      - name: concourse-pipeline
        type: docker-image
        source:
          repository: concourse/concourse-pipeline-resource
          tag: 3
      - name: bosh-deployment-v2
        type: docker-image
        source:
          repository: cloudfoundry/bosh-deployment-resource
          tag: v2.12.0
      - name: bosh-errand
        type: docker-image
        source:
          repository: starkandwayne/bosh2-errand-resource
          tag: v0.1.2
    YAML
    YAML.safe_load(resource_types_yaml)
  end
  let(:groups) do
    groups_yaml = [
      { 'name' => 'My-root-depls',
        'jobs' =>
         ['approve-and-delete-disabled-deployments',
          'cancel-all-bosh-tasks',
          'cloud-config-and-runtime-config-for-my-root-depls',
          'delete-deployments-review',
          'deploy-bui',
          'deploy-shield-expe',
          'execute-deploy-script',
          'init-concourse-boshrelease-and-stemcell-for-my-root-depls',
          'recreate-all',
          'recreate-bui',
          'recreate-shield-expe',
          'retrigger-all-jobs',
          'run-errand-shield-expe'] },
      { 'name' => 'Deploy-b*', 'jobs' => ['deploy-bui'] },
      { 'name' => 'Deploy-s*', 'jobs' => ['deploy-shield-expe', 'run-errand-shield-expe'] },
      { 'name' => 'Recreate',
        'jobs' => ['recreate-all', 'recreate-bui', 'recreate-shield-expe'] },
      { 'name' => 'Utils',
        'jobs' =>
        ['approve-and-delete-disabled-deployments',
         'cancel-all-bosh-tasks',
         'cloud-config-and-runtime-config-for-my-root-depls',
         'delete-deployments-review',
         'execute-deploy-script',
         'init-concourse-boshrelease-and-stemcell-for-my-root-depls',
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
          #{root_deployment_name}-generated:
            config_file: path/located/in/secrets-repo/pipelines/#{root_deployment_name}-generated.yml
            vars_files:
            - another/path/located/in/secrets-repo/pipelines/credentials-iaas-specific.yml
            - #{root_deployment_name}/#{root_deployment_name}-versions.yml
          #{root_deployment_name}-cf-apps-generated:
            config_file: path/located/in/secrets-repo/pipelines/#{root_deployment_name}-generated.yml
            vars_files:
            - another/path/located/in/secrets-repo/pipelines/credentials-iaas-specific.yml
            - #{root_deployment_name}/#{root_deployment_name}-versions.yml
    YAML
    YAML.safe_load ci_deployments_yaml
  end

  context 'when processing depls-pipeline.yml.erb' do
    subject { TemplateProcessor.new root_deployment_name, config, processor_context }

    before(:context) do
      @output_dir = Dir.mktmpdir('generated-pipelines')
      @pipelines_output_dir = File.join(@output_dir, 'pipelines')
      @template_pipeline_name = 'depls-pipeline.yml.erb'
      @pipelines_dir = Dir.mktmpdir('pipeline-templates')

      FileUtils.copy("concourse/pipelines/template/#{@template_pipeline_name}", @pipelines_dir)
    end

    after(:context) do
      FileUtils.rm_rf(@output_dir)
      FileUtils.rm_rf(@pipelines_dir)
    end

    let(:config) { { dump_output: true, output_path: @output_dir } }
    let(:generated_pipeline) do
      pipeline_template = @processed_template[File.join(@pipelines_dir, @template_pipeline_name)]
      generated_pipeline_path = File.join(@pipelines_output_dir, pipeline_template)
      YAML.load_file(generated_pipeline_path)
    end

    before { @processed_template = subject.process(@pipelines_dir + '/*') }

    context 'when an errand job is defined' do
      let(:expected_shield_errand) do
        my_shield_errand_yaml = <<~YAML
          - aggregate:
            - get: secrets-shield-expe
              params: { submodules: none}
              trigger: true
              passed: [deploy-shield-expe]
            - get: paas-templates-shield-expe
              params: { submodules: none}
              trigger: true
              passed: [deploy-shield-expe]
          - put: errand-shield-expe
            params:
              name: import
        YAML
        YAML.safe_load(my_shield_errand_yaml)
      end
      let(:expected_shield_errand_resource) do
        my_shield_errand_yaml = <<~YAML
          - name: errand-shield-expe
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

      it 'generates an errand resource for shield boshrelease' do
        generated_errand_resource = generated_pipeline['resources'].select { |job| job['name'] == 'errand-shield-expe' } # .flat_map { |job| job['plan'] }
        expect(generated_errand_resource).to match(expected_shield_errand_resource)
      end

      it 'generates an errand job for shield boshrelease' do
        generated_errand_job = generated_pipeline['jobs'].select { |job| job['name'] == 'run-errand-shield-expe' }.flat_map { |job| job['plan'] }
        expect(generated_errand_job).to match(expected_shield_errand)
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
        generated_group = generated_pipeline['groups'].select { |concourse_group| concourse_group['name'] == root_deployment_name.capitalize }
        expect(generated_group).not_to be_empty
      end
    end

    context 'when boshrelease offline mode is enabled' do
      let(:expected_boshreleases) do
        { 'cf-routing-release' => 'cloudfoundry-incubator',
          'route-registrar-boshrelease' => 'cloudfoundry-community',
          'haproxy-boshrelease' => 'cloudfoundry-community' }
      end
      let(:expected_s3_boshreleases) do
        expected_yaml = expected_boshreleases.map do |br_name, br_repo|
          fragment = <<~YAML
            - name: #{br_name}
              type: s3
              source:
                bucket: ((s3-br-bucket))
                region_name: ((s3-br-region-name))
                regexp: #{br_repo}/#{br_name}-(.*).tgz
                access_key_id: ((s3-br-access-key-id))
                secret_access_key: ((s3-br-secret-key))
                endpoint: ((s3-br-endpoint))
                skip_ssl_verification: ((s3-br-skip-ssl-verification))
          YAML
          YAML.safe_load fragment
        end.flatten
      end
      let(:expected_boshrelease_get_version) do
        expected_boshreleases.flat_map { |name, repo| { name => "#{repo}/#{name}-((#{name}-version)).tgz" } }
      end
      let(:expected_boshrelease_put_version) do
        expected_boshreleases.flat_map { |name, _repo| { name => "#{name}/#{name}-((#{name}-version)).tgz" } }
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

      it 'generates s3 bosh release resource' do
        s3_boshreleases = generated_pipeline['resources'].select { |resource| resource['type'] == 's3' }
        expect(s3_boshreleases).to include(*expected_s3_boshreleases)
      end

      it 'generates s3 version using path on get' do
        boshrelease_get_version = generated_pipeline['jobs'].flat_map { |job| job['plan'] }
          .flat_map { |plan| plan['aggregate'] }
          .compact
          .select { |resource| expected_boshreleases.key?(resource['get']) }
          .flat_map { |resource| { resource['get'] => resource['version']['path'] } }
        expect(boshrelease_get_version).to include(*expected_boshrelease_get_version)
      end

      it 'generates s3 version using path on deployment put' do
        s3_deployments = expected_s3_deployment_put.flat_map(&:keys)
        deployment_put_version = generated_pipeline['jobs'].flat_map { |job| job['plan'] }
          .select { |resource| s3_deployments.include?(resource['put']) }
          .flat_map { |resource| { resource['put'] => resource['params']['releases'] } }
        expect(deployment_put_version).to include(*expected_s3_deployment_put)
      end

      it 'generates init-concourse-boshrelease-and-stemcell-for-ops-depls' do
        expected_init_version = expected_boshrelease_get_version.flat_map(&:values).flatten.flat_map { |get_version| "path:#{get_version}" }
        init_args = generated_pipeline['jobs']
          .select { |job| job['name'] == "init-concourse-boshrelease-and-stemcell-for-#{root_deployment_name}" }
          .flat_map { |job| job['plan'] }
          .select { |step| step['task'] && step['task'] == "generate-#{root_deployment_name}-flight-plan" }
          .flat_map { |task| task['config']['run']['args'] }
        expect(init_args[1]).to include(*expected_init_version)
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
            type: bosh-io-stemcell
            source:
              name: ((stemcell-name-prefix))((stemcell-main-name))
        YAML
        YAML.safe_load expected_yaml
      end
      let(:expected_stemcell_deploy_get) { ['((stemcell-version))'] * 2 }
      let(:expected_stemcell_deploy_put) { ['((stemcell-main-name))/stemcell.tgz'] * 2 }
      let(:expected_stemcell_init) { 'echo "check-resource -r $BUILD_PIPELINE_NAME/((stemcell-main-name)) --from version:((stemcell-version))" | tee -a result-dir/flight-plan' }

      it 'generates bosh-io stemcell' do
        bosh_io_stemcell = generated_pipeline['resources'].select { |resource| resource['type'] == 'bosh-io-stemcell' }
        expect(bosh_io_stemcell).to include(*expected_bosh_io_stemcell)
      end

      it 'generates bosh_io version using path on get' do
        stemcell_get_version = generated_pipeline['jobs'].flat_map { |job| job['plan'] }
          .flat_map { |plan| plan['aggregate'] }
          .compact
          .select { |resource| resource['get'] == '((stemcell-main-name))' }
          .flat_map { |resource| resource['version']['version'] }
        expect(stemcell_get_version).to match(expected_stemcell_deploy_get)
      end

      it 'generates bosh-io stemcell on deployment put' do
        deployment_put_version = generated_pipeline['jobs'].flat_map { |job| job['plan'] }
          .select { |resource| resource['params']&.has_key?('stemcells') }
          .flat_map { |resource| resource['params']['stemcells'] }
        expect(deployment_put_version).to match(expected_stemcell_deploy_put)
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
              #{root_deployment_name}-generated:
                config_file: path/located/in/secrets-repo/pipelines/#{root_deployment_name}-generated.yml
                vars_files:
                - another/path/located/in/secrets-repo/pipelines/credentials-iaas-specific.yml
                - #{root_deployment_name}/#{root_deployment_name}-versions.yml
              #{root_deployment_name}-cf-apps-generated:
                config_file: path/located/in/secrets-repo/pipelines/#{root_deployment_name}-generated.yml
                vars_files:
                - another/path/located/in/secrets-repo/pipelines/credentials-iaas-specific.yml
                - #{root_deployment_name}/#{root_deployment_name}-versions.yml
        YAML
        YAML.safe_load ci_deployments_yaml
      end

      it 'generates all resource_types' do
        expect(generated_pipeline['resource_types']).to match_array(expected_resource_types)
      end

      it 'generates all groups' do
        groups.select { |item| %w[Utils My-root-depls].include?(item['name']) }.each do |item|
          item['jobs'] << 'update-pipeline-my-root-depls-generated'
          item['jobs'].sort!
        end
        expect(generated_pipeline['groups']).to match_array(groups)
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
              #{root_deployment_name}-generated:
                config_file: path/located/in/secrets-repo/pipelines/#{root_deployment_name}-generated.yml
                vars_files:
                - another/path/located/in/secrets-repo/pipelines/credentials-iaas-specific.yml
                - #{root_deployment_name}/#{root_deployment_name}-versions.yml
              #{root_deployment_name}-cf-apps-generated:
                config_file: path/located/in/secrets-repo/pipelines/#{root_deployment_name}-generated.yml
                vars_files:
                - another/path/located/in/secrets-repo/pipelines/credentials-iaas-specific.yml
                - #{root_deployment_name}/#{root_deployment_name}-versions.yml

        YAML
        YAML.safe_load ci_deployments_yaml
      end

      it 'generates all resource_types' do
        expect(generated_pipeline['resource_types']).to match(expected_resource_types)
      end

      it 'generates terraform group' do
        expected_tf_group = { 'name' => 'Terraform',
                              'jobs' =>
                                     ['approve-and-enforce-terraform-consistency',
                                      'check-terraform-consistency'] }
        generated = generated_pipeline['groups'].select { |group| group['name'] == 'Terraform' }.pop
        expect(generated).to match(expected_tf_group)
      end

      it 'generates a valid check-terraform-consistency job' do
        expected_tf_job =
          [
            { "task" => 'generate-terraform-tfvars',
              "input_mapping" =>
                { "scripts-resource" => "cf-ops-automation", "credentials-resource" => "secrets-my-root-depls-limited", "additional-resource" => "paas-templates-my-root-depls" },
              "output_mapping" => { "generated-files" => "terraform-tfvars" },
              "file" => "cf-ops-automation/concourse/tasks/generate-manifest.yml",
              "params" =>
             { "YML_FILES" =>
                         "./credentials-resource/shared/secrets.yml\n./credentials-resource/my-tfstate-location/secrets/meta.yml\n./credentials-resource/my-tfstate-location/secrets/secrets.yml\n",
               "YML_TEMPLATE_DIR" => "additional-resource/my-tfstate-location/template",
               "CUSTOM_SCRIPT_DIR" => "additional-resource/my-tfstate-location/template",
               "SUFFIX" => "-tpl.tfvars.yml",
               "IAAS_TYPE" => "((iaas-type))" } },
            { "task" => "terraform-plan",
              "input_mapping" =>
                   { "secret-state-resource" => "secrets-my-root-depls-limited",
                     "spec-resource" => "paas-templates-my-root-depls" },
              "file" => "cf-ops-automation/concourse/tasks/terraform_plan_cloudfoundry.yml",
              "params" =>
                   { "SPEC_PATH" => "my-tfstate-location/spec",
                     "SECRET_STATE_FILE_PATH" => "my-tfstate-location",
                     "IAAS_SPEC_PATH" => "my-tfstate-location/spec-((iaas-type))" } }
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
      let(:check_terraform_aggregate) { check_terraform_plans.flat_map { |tasks| tasks['aggregate'] }.compact }
      let(:check_terraform_secrets_triggering) { check_terraform_aggregate.select { |task| task['get'].start_with?('secrets-') }.flat_map { |task| task['trigger'] } }
      let(:check_terraform_paas_templates_triggering) { check_terraform_aggregate.select { |task| task['get'].start_with?('paas-templates-') }.flat_map { |task| task['trigger'] } }
      let(:enforce_terraform_jobs) { generated_pipeline['jobs'].select { |resource| resource['name'].start_with?('approve-and-enforce-terraform-consistency') } }
      let(:enforce_terraform_plans) { enforce_terraform_jobs.flat_map { |job| job['plan'] } }
      let(:enforce_terraform_aggregate) { enforce_terraform_plans.flat_map { |tasks| tasks['aggregate'] }.compact }
      let(:enforce_terraform_all_secrets_triggering) { enforce_terraform_aggregate.select { |task| task['get'].start_with?('secrets-') }.flat_map { |task| task['trigger'] } }
      let(:enforce_terraform_paas_templates_triggering) { enforce_terraform_aggregate.select { |task| task['get'].start_with?('paas-templates-') }.flat_map { |task| task['trigger'] } }
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
end
