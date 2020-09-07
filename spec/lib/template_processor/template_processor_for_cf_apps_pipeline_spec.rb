require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'template_processor'
require 'ci_deployment'
require_relative 'test_fixtures'

describe 'CfAppsPipelineTemplateProcessing' do
  let(:root_deployment_name) { 'my-root-depls' }
  let(:ops_automation_path) { '.' }
  let(:processor_context) do
    { depls: root_deployment_name,
      all_ci_deployments: all_ci_deployments,
      all_cf_apps: all_cf_apps,
      config: loaded_config,
      ops_automation_path: ops_automation_path }
  end
  let(:secrets_dirs_overview) { {} }
  let(:root_deployment_versions) { {} }
  let(:all_cf_apps) do
    cf_apps_yaml = <<~YAML
      ---
      ops-dataflow:
        cf_api_url: https://api.my-cloudfoundry.org
        cf_username: my_user
        cf_password: myPaSsWord
        cf_organization: my_domain
        cf_space: ops-dataflow
        base-dir: ops-depls/cf-apps-deployments/ops-dataflow
      elpaaso-sandbox:
        cf_api_url: https://api.my-cloudfoundry.org
        cf_username: my_user
        cf_password: '"aPwD;%:-)>Ko'
        cf_organization: my_domain
        cf_space: elpaaso-sandbox
        base-dir: ops-depls/cf-apps-deployments/elpaaso-sandbox
      log-broker:
        cf_api_url: https://api.my-cloudfoundry.org
        cf_username: my_user
        cf_password: "'aPwD;%:-)>Ko"
        cf_organization: my_domain
        cf_space: log-brokers
        base-dir: ops-depls/cf-apps-deployments/log-sec-broker
      mattermost:
        cf_api_url: https://api.my-cloudfoundry.org
        cf_username: my_user
        cf_password: myPaSsWord
        cf_organization: my_domain
        cf_space: mattermost
        base-dir: ops-depls/cf-apps-deployments/mattermost
    YAML
    YAML.safe_load(cf_apps_yaml)
  end
  let(:custom_team) { 'my-custom-team' }
  let(:all_ci_deployments) do
    ci_deployments_yaml = <<~YAML
      #{root_deployment_name}:
        target_name: my-concourse-name
        pipelines:
          #{root_deployment_name}-bosh-generated:
          #{root_deployment_name}-cf-apps-generated:
            team: #{custom_team}
    YAML
    YAML.safe_load ci_deployments_yaml
  end
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
    YAML
    YAML.safe_load(resource_types_yaml)
  end
  let(:groups) do
    [
      { 'name' => 'my-root-depls',
        'jobs' => %w[retrigger-all-jobs cf-push-elpaaso-sandbox cf-push-log-broker cf-push-mattermost cf-push-ops-dataflow] },
      { "name" => "app-e", "jobs" => ["cf-push-elpaaso-sandbox"] },
      { "name" => "app-l", "jobs" => ["cf-push-log-broker"] },
      { "name" => "app-m", "jobs" => ["cf-push-mattermost"] },
      { "name" => "app-o", "jobs" => ["cf-push-ops-dataflow"] },
      { "name" => "utils", "jobs" => ["retrigger-all-jobs"] }
    ]
  end

  context 'when processing cf-apps-pipeline.yml.erb' do
    subject { TemplateProcessor.new root_deployment_name, config, processor_context }

    before(:context) do
      @output_dir = Dir.mktmpdir('generated-pipelines')
      @pipelines_output_dir = File.join(@output_dir, 'pipelines')
      @template_pipeline_name = 'cf-apps-pipeline.yml.erb'
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

    context 'with minimal config' do
      let(:fly_into_concourse_context) do
        { depls: root_deployment_name,
          team: custom_team }
      end
      let(:expected_fly_into_concourse) { Coa::TestFixtures.expand_task_params_template('fly-into-concourse', fly_into_concourse_context) }

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

      it 'generates all groups' do
        expect(generated_pipeline['groups']).to match(groups)
      end

      it 'generates a group using root deployment name ' do
        generated_groups = generated_pipeline['groups'].select { |concourse_group| concourse_group['name'] == root_deployment_name.downcase }
        expect(generated_groups).not_to be_empty
      end

      it 'generates CF variables available for post-deploy' do
        cf_push_params = generated_pipeline['jobs'].flat_map { |job| job['plan'] }
          .select { |step| step['task']&.start_with?("push") }.flat_map { |step| step['params'] }

        cf_push_params.each do |task_params|
          expect(task_params).to include('CF_API_URL', 'CF_ORG', 'CF_SPACE', 'CF_USERNAME', 'CF_PASSWORD')
        end
      end

      it 'generates retrigger all' do
        fly_into_concourse_params = generated_pipeline['jobs'].flat_map { |job| job['plan'] }
          .select { |step| step['task']&.start_with?("fly-into-concourse") }.flat_map { |step| step['params'] }

        fly_into_concourse_params.each do |task_params|
          expect(task_params).to match(expected_fly_into_concourse)
        end
      end
    end
  end
end
