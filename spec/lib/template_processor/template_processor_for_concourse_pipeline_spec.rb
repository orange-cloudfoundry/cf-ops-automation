require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'template_processor'
require 'ci_deployment'
require 'deployment_deployers_config'

describe 'ConcoursePipelineTemplateProcessing (ie: concourse-pipeline.yml.erb)' do
  subject { TemplateProcessor.new root_deployment_name, config, processor_context }

  let(:root_deployment_name) { 'my-root-depls' }
  let(:secrets_dirs_overview) { {} }
  let(:root_deployment_versions) { {} }
  let(:all_ci_deployments) { {} }
  let(:git_submodules) { {} }
  let(:processor_context) do
    { depls: root_deployment_name,
      all_dependencies: all_dependencies,
      all_ci_deployments: all_ci_deployments,
      git_submodules: git_submodules,
      config: loaded_config }
  end
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
          status: enabled
      cached-buildpack:
          concourse:
            active: true
          status: enabled
      another-cached-buildpack:
          concourse:
            active: true
          status: enabled
    YAML
    YAML.safe_load(deps_yaml)
  end
  let(:concourse_active_deployments) { all_dependencies.select { |_, info| info['concourse'] && info['concourse']['active'] } }
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
          repository: cfcommunity/slack-notification-resource
          tag: v1.4.2
      - name: concourse-pipeline
        type: docker-image
        source:
          repository: concourse/concourse-pipeline-resource
          tag: 3
    YAML
    YAML.safe_load(resource_types_yaml)
  end

  before(:context) do
    @template_pipeline_name = 'concourse-pipeline.yml.erb'
    @output_dir = Dir.mktmpdir('generated-pipelines')
    @pipelines_output_dir = File.join(@output_dir, 'pipelines')
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

  context 'when coucourse-pipeline is valid' do
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
      expect(generated_pipeline['resource_types']).to match_array(expected_resource_types)
    end

    it 'does not generate any groups' do
      expected_group = generated_pipeline['groups']
      expect(expected_group).to be_nil
    end
  end

  context 'when resources are corrects' do
    context 'when static resources are valid' do
      let(:expected_static_resources) do
        %w[
          failure-alert
          cf-ops-automation
        ] << "concourse-for-#{root_deployment_name}"
      end
      let(:expected_failure_alert) do
        my_yaml = <<~YAML
          - name: failure-alert
            type: slack-notification
            source:
              url: ((slack-webhook))
              proxy: ((slack-proxy))
              proxy_https_tunnel: ((slack-proxy-https-tunnel))
              disable: ((slack-disable))
        YAML
        YAML.safe_load my_yaml
      end
      let(:expected_concourse) do
        my_yaml = <<~YAML
          - name: concourse-for-#{root_deployment_name}
            type: concourse-pipeline
            source:
              target: ((concourse-#{root_deployment_name}-target))
              insecure: ((concourse-#{root_deployment_name}-insecure))
              teams:
               - name: main
                 username: ((concourse-#{root_deployment_name}-username))
                 password: ((concourse-#{root_deployment_name}-password))
        YAML
        YAML.safe_load my_yaml
      end
      let(:expected_cf_ops_automation) do
        my_yaml = <<~YAML
          - name: cf-ops-automation
            type: git
            source:
               uri: ((cf-ops-automation-uri))
               branch: ((cf-ops-automation-branch))
               tag_filter: ((cf-ops-automation-tag-filter))
               skip_ssl_verification: true
        YAML
        YAML.safe_load my_yaml
      end
      let(:generated_resource_names) { generated_pipeline['resources'].flat_map { |resource| resource['name'] } }
      let(:generated_resources) { generated_pipeline['resources'] }

      it 'includes static resources' do
        expect(generated_resource_names).to include(*expected_static_resources)
      end

      it 'generates a valid cf_ops_automation resource' do
        expect(generated_resources).to include(*expected_cf_ops_automation)
      end

      it 'generates a valid concourse resource' do
        expect(generated_resources).to include(*expected_concourse)
      end

      it 'generates a valid failure_alert resource' do
        expect(generated_resources).to include(*expected_failure_alert)
      end
    end
    context 'when dynamic resources are valid' do
      let(:expected_paas_templates_resources) do
        my_yaml = ''
        concourse_active_deployments.each_key do |name|
          my_yaml += <<~YAML
            - name: paas-templates-#{name}
              type: git
              source:
                uri: ((paas-templates-uri))
                paths:
                - '#{root_deployment_name}/#{name}/#{DeploymentDeployersConfig::CONCOURSE_CONFIG_DIRNAME}'
                - '#{root_deployment_name}/#{root_deployment_name}-versions.yml'
                branch: ((paas-templates-branch))
                skip_ssl_verification: true
          YAML
        end
        YAML.safe_load my_yaml
      end
      let(:expected_secrets_resources) do
        my_yaml = ''
        concourse_active_deployments.each_key do |name|
          my_yaml += <<~YAML
            - name: secrets-#{name}
              type: git
              source:
                uri: ((secrets-uri))
                paths:
                - "#{root_deployment_name}/#{name}"
                - 'shared'
                branch: ((secrets-branch))
                skip_ssl_verification: true
          YAML
        end
        YAML.safe_load my_yaml
      end

      let(:expected_dynamic_resources) do
        resources = []
        concourse_deployment = all_dependencies.select { |_, info| info['concourse'] && info['concourse']['active'] }
        concourse_deployment.each_key do |deployment_name|
          resources << "paas-templates-#{deployment_name}"
          resources << "secrets-#{deployment_name}"
        end
        resources
      end

      it 'includes dynamic resources' do
        generated_resources = generated_pipeline['resources'].flat_map { |resource| resource['name'] }
        expect(generated_resources).to include(*expected_dynamic_resources)
      end

      it 'matches paas-templates reference' do
        generated_resources = generated_pipeline['resources'].select { |resource| resource['name'].start_with?('paas-templates-') }
        expect(generated_resources).to match_array(expected_paas_templates_resources)
      end

      it 'matches secrets reference' do
        generated_secrets_resources = generated_pipeline['resources'].select { |resource| resource['name'].start_with?('secrets-') }
        expect(generated_secrets_resources).to match_array(expected_secrets_resources)
      end
    end
  end

  context 'when a deploy-concourse job is correct' do
    let(:expected_defined_tasks) do
      tasks = %w[bosh-interpolate-pipeline-with-ops-and-vars-files concourse-for-my-root-depls]
      concourse_active_deployments.each_key do |name|
        tasks << "spruce-processing-#{name}"
        tasks << "execute-#{name}-spiff-pre-deploy"
        tasks << "copy-#{name}-required-files"
        tasks << "execute-#{name}-post-deploy"
        tasks << 'bosh-interpolate-pipeline-with-ops-and-vars-files'
        tasks << 'concourse-for-my-root-depls'
      end
      tasks
    end
    let(:deploy_concourse_tasks) do
      generated_pipeline['jobs'].select { |job| job['name'].start_with?('deploy-concourse') }
        .flat_map { |job| job['plan'] }
    end

    it 'generates required task for deploy-pipeline' do
      generated_tasks = generated_pipeline['jobs'].select { |job| job['name'].start_with?('deploy-concourse') }
        .flat_map { |job| job['plan'] }
        .flat_map { |type| type['put'] || type['task'] }
        .compact
        .uniq
      expect(generated_tasks).to match_array(expected_defined_tasks.uniq)
    end

    context 'when generating spruce tasks' do
      let(:expected_spruce_processing_tasks) do
        my_yaml = ''
        concourse_active_deployments.each_key do |name|
          my_yaml += <<~YAML
            - task: spruce-processing-#{name}
              input_mapping: {scripts-resource: cf-ops-automation, credentials-resource: secrets-#{name}, additional-resource: paas-templates-#{name}}
              output_mapping: {generated-files: spruced-files}
              file: cf-ops-automation/concourse/tasks/generate-manifest.yml
              params:
                SPRUCE_FILE_BASE_PATH: credentials-resource/#{root_deployment_name}/#{name}
                YML_TEMPLATE_DIR: additional-resource/#{root_deployment_name}/#{name}/#{DeploymentDeployersConfig::CONCOURSE_CONFIG_DIRNAME}
                YML_FILES: |
                    ./credentials-resource/#{root_deployment_name}/#{name}/secrets/secrets.yml
                    ./credentials-resource/shared/secrets.yml
                CUSTOM_SCRIPT_DIR: additional-resource/#{root_deployment_name}/#{name}/#{DeploymentDeployersConfig::CONCOURSE_CONFIG_DIRNAME}
                IAAS_TYPE: ((iaas-type))

          YAML
        end
        YAML.safe_load my_yaml
      end

      it 'is valid' do
        generated_spruce_tasks = deploy_concourse_tasks.select { |task| task['task']&.start_with?('spruce-processing') }
        expect(generated_spruce_tasks).to match_array(expected_spruce_processing_tasks)
      end
    end

    context 'when generating pre-deploy task' do
      let(:expected_execute_pre_deploy_tasks) do
        my_yaml = ''
        concourse_active_deployments.each_key do |name|
          my_yaml += <<~YAML
            - task: execute-#{name}-spiff-pre-deploy
              input_mapping: {scripts-resource: cf-ops-automation, template-resource: paas-templates-#{name}, credentials-resource: secrets-#{name}, additional-resource: spruced-files}
              output_mapping: {generated-files: pre-deploy-resource}
              file: cf-ops-automation/concourse/tasks/spiff_pre_bosh_deploy.yml
              params:
                CUSTOM_SCRIPT_DIR: template-resource/#{root_deployment_name}/#{name}/#{DeploymentDeployersConfig::CONCOURSE_CONFIG_DIRNAME}
                SECRETS_DIR: credentials-resource/#{root_deployment_name}/#{name}
          YAML
        end
        YAML.safe_load my_yaml
      end

      it 'is valid' do
        generated_pre_deploy_tasks = deploy_concourse_tasks.select { |task| task['task']&.end_with?('-pre-deploy') }
        expect(generated_pre_deploy_tasks).to match_array(expected_execute_pre_deploy_tasks)
      end
    end

    context 'when generating execute-post-deploy task' do
      let(:expected_execute_post_deploy_tasks) do
        my_yaml = ''
        concourse_active_deployments.each_key do |name|
          my_yaml += <<~YAML
            - task: execute-#{name}-post-deploy
              input_mapping: {scripts-resource: cf-ops-automation, template-resource: paas-templates-#{name}, credentials-resource: secrets-#{name}, additional-resource: final-#{name}-pipeline}
              output_mapping: {generated-files: post-deploy-result}
              file: cf-ops-automation/concourse/tasks/post_bosh_deploy.yml
              params:
                CUSTOM_SCRIPT_DIR: template-resource/#{root_deployment_name}/#{name}/#{DeploymentDeployersConfig::CONCOURSE_CONFIG_DIRNAME}
                SECRETS_DIR: credentials-resource/#{root_deployment_name}/#{name}
          YAML
        end
        YAML.safe_load my_yaml
      end

      it 'is valid' do
        generated_post_deploy_tasks = deploy_concourse_tasks.select { |task| task['task']&.end_with?('-post-deploy') }
        expect(generated_post_deploy_tasks).to match_array(expected_execute_post_deploy_tasks)
      end
    end

    context 'when generating execute-copy-required task' do
      let(:expected_execute_copies_required_files_tasks) do
        my_yaml = ''
        concourse_active_deployments.each_key do |name|
          my_yaml += <<~YAML
            - task: copy-#{name}-required-files
              input_mapping: {scripts-resource: cf-ops-automation, template-resource: paas-templates-#{name}, credentials-resource: secrets-#{name}, additional-resource: pre-deploy-resource}
              output_mapping: {generated-files: bosh-inputs}
              file: cf-ops-automation/concourse/tasks/copy_deployment_required_files.yml
              params:
                CUSTOM_SCRIPT_DIR: template-resource/#{root_deployment_name}/#{name}/#{DeploymentDeployersConfig::CONCOURSE_CONFIG_DIRNAME}
                SECRETS_DIR: credentials-resource/#{root_deployment_name}/#{name}
                MANIFEST_NAME: #{name}.yml
          YAML
        end
        YAML.safe_load my_yaml
      end

      it 'is valid' do
        generated_required_file_tasks = deploy_concourse_tasks.select { |task| task['task']&.end_with?('-required-files') }
        expect(generated_required_file_tasks).to match_array(expected_execute_copies_required_files_tasks)
      end
    end

    context 'when generating bosh-interpolate task'
    context 'when generating concourse task' do
      let(:expected_concourse_tasks) do
        my_yaml = ''
        concourse_active_deployments.each_key do |name|
          my_yaml += <<~YAML
            #{root_deployment_name}-#{name}:
             - put: concourse-for-#{root_deployment_name}
               params:
                 pipelines:
                 - name: #{root_deployment_name}-#{name}
                   team: main
                   config_file: final-#{name}-pipeline/interpolated-#{name}.yml
          YAML
        end
        YAML.safe_load my_yaml
      end

      it 'is valid' do
        # generated_concourse_tasks = deploy_concourse_tasks.select { |task| task['put']&.start_with?('concourse-for-') }
        generated_concourse_tasks = deploy_concourse_tasks.flat_map { |task| { task['params']['pipelines'].first['name'] => [task] } if task['put']&.start_with?('concourse-for-') }
          .compact
          .inject({}) { |memo, task| memo.merge task }
        expect(generated_concourse_tasks).to match(expected_concourse_tasks)
      end
    end
  end

  # context 'when boshrelease offline mode is enabled' do
  #   let(:expected_boshreleases) do
  #     { 'cf-routing-release' => 'cloudfoundry-incubator',
  #       'route-registrar-boshrelease' => 'cloudfoundry-community',
  #       'haproxy-boshrelease' => 'cloudfoundry-community' }
  #   end
  #   let(:expected_s3_boshreleases) do
  #     expected_yaml = expected_boshreleases.map do |br_name, br_repo|
  #       fragment = <<~YAML
  #         - name: #{br_name}
  #           type: s3
  #           source:
  #             bucket: ((s3-br-bucket))
  #             region_name: ((s3-br-region-name))
  #             regexp: #{br_repo}/#{br_name}-(.*).tgz
  #             access_key_id: ((s3-br-access-key-id))
  #             secret_access_key: ((s3-br-secret-key))
  #             endpoint: ((s3-br-endpoint))
  #             skip_ssl_verification: ((s3-br-skip-ssl-verification))
  #         YAML
  #       YAML.safe_load fragment
  #     end.flatten
  #   end
  #   let(:expected_boshrelease_get_version) do
  #     expected_boshreleases.flat_map { |name, repo| { name => "#{repo}/#{name}-((#{name}-version)).tgz" } }
  #   end
  #   let(:expected_boshrelease_put_version) do
  #     expected_boshreleases.flat_map { |name, _repo| { name => "#{name}/#{name}-((#{name}-version)).tgz" } }
  #   end
  #   let(:expected_s3_deployment_put) do
  #     expected_yaml = <<~YAML
  #       - bui-deployment:
  #         - #{expected_boshrelease_put_version.flat_map { |br| br['haproxy-boshrelease'] }.compact.first}
  #         - #{expected_boshrelease_put_version.flat_map { |br| br['route-registrar-boshrelease'] }.compact.first}
  #       - shield-expe-deployment:
  #         - #{expected_boshrelease_put_version.flat_map { |br| br['cf-routing-release'] }.compact.first}
  #       YAML
  #     YAML.safe_load expected_yaml
  #   end
  #
  #   it 'generates s3 bosh release resource' do
  #     s3_boshreleases = generated_pipeline['resources'].select { |resource| resource['type'] == 's3' }
  #     expect(s3_boshreleases).to include(*expected_s3_boshreleases)
  #   end
  #
  #   it 'generates s3 version using path on get' do
  #     boshrelease_get_version = generated_pipeline['jobs'].flat_map { |job| job['plan'] }
  #                                                         .flat_map { |plan| plan['aggregate'] }
  #                                                         .compact
  #                                                         .select { |resource| expected_boshreleases.keys.include?(resource['get']) }
  #                                                         .flat_map { |resource| { resource['get'] => resource['version']['path'] } }
  #     expect(boshrelease_get_version).to include(*expected_boshrelease_get_version)
  #   end
  #
  #   it 'generates s3 version using path on deployment put' do
  #     s3_deployments = expected_s3_deployment_put.flat_map(&:keys)
  #     deployment_put_version = generated_pipeline['jobs'].flat_map { |job| job['plan'] }
  #                                                        .select { |resource| s3_deployments.include?(resource['put']) }
  #                                                        .flat_map { |resource| { resource['put'] => resource['params']['releases'] } }
  #     expect(deployment_put_version).to include(*expected_s3_deployment_put)
  #   end
  #
  #   it 'generates init-concourse-boshrelease-and-stemcell-for-ops-depls' do
  #     expected_init_version = expected_boshrelease_get_version.flat_map(&:values).flatten.flat_map { |get_version| "path:#{get_version}" }
  #     init_args = generated_pipeline['jobs']
  #                 .select { |job| job['name'] == "init-concourse-boshrelease-and-stemcell-for-#{root_deployment_name}" }
  #                 .flat_map { |job| job['plan'] }
  #                 .select { |step| step['task'] && step['task'] == "generate-#{root_deployment_name}-flight-plan" }
  #                 .flat_map { |task| task['config']['run']['args'] }
  #     expect(init_args[1]).to include(*expected_init_version)
  #   end
  # end

  context 'when deploy-concourse job triggering is correct' do
    let(:deploy_concourse_jobs) { generated_pipeline['jobs'].select { |resource| resource['name'].start_with?('deploy-concourse-') } }
    let(:deploy_concourse_plans) { deploy_concourse_jobs.flat_map { |job| job['plan'] } }
    let(:deploy_concourse_aggregate) { deploy_concourse_plans.flat_map { |tasks| tasks['aggregate'] }.compact }
    let(:concourse_trigger_secrets) { deploy_concourse_aggregate.select { |task| task['get'].start_with?('secrets-') }.flat_map { |task| task['trigger'] } }
    let(:concourse_trigger_paas_templates) { deploy_concourse_aggregate.select { |task| task['get'].start_with?('paas-templates-') }.flat_map { |task| task['trigger'] } }
    let(:concourse_trigger_other_resources) { deploy_concourse_aggregate.select { |task| !task['get'].start_with?('secrets-') && !task['get'].start_with?('paas-templates-') }.flat_map { |task| task['trigger'] } }

    it 'triggers on secrets update' do
      expect(concourse_trigger_secrets.uniq).to match([true])
    end

    it 'triggers on paas-templates update' do
      expect(concourse_trigger_paas_templates.uniq).to match([true])
    end

    it 'does not trigger on other resource' do
      expect(concourse_trigger_other_resources.uniq).to match([false])
    end
  end
end
