require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'template_processor'
require 'ci_deployment'

describe 'CfAppsPipelineTemplateProcessing' do
  let(:root_deployment_name) { 'my-root-depls' }
  let(:processor_context) do
    { depls: root_deployment_name,
      all_cf_apps: all_cf_apps,
      config: loaded_config }
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
        cf_password: myPaSsWord
        cf_organization: my_domain
        cf_space: elpaaso-sandbox
        base-dir: ops-depls/cf-apps-deployments/elpaaso-sandbox
      log-broker:
        cf_api_url: https://api.my-cloudfoundry.org
        cf_username: my_user
        cf_password: myPaSsWord
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
  let(:all_ci_deployments) { {} }
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

      - name: cron-resource
        type: docker-image
        source:
          repository: cftoolsmiths/cron-resource
    YAML
    YAML.safe_load(resource_types_yaml)
  end
  let(:groups) do
    [
      { 'name' => 'My-root-depls',
        'jobs' =>
        ["retrigger-all-jobs",
         "cf-push-elpaaso-sandbox",
         "cf-push-log-broker",
         "cf-push-mattermost",
         "cf-push-ops-dataflow"]},
         {"name"=>"App-e*", "jobs"=>["cf-push-elpaaso-sandbox"]},
         {"name"=>"App-l*", "jobs"=>["cf-push-log-broker"]},
         {"name"=>"App-m*", "jobs"=>["cf-push-mattermost"]},
         {"name"=>"App-o*", "jobs"=>["cf-push-ops-dataflow"]},
         {"name"=>"Utils", "jobs"=>["retrigger-all-jobs"]}
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
        generated_groups = generated_pipeline['groups'].select { |concourse_group| concourse_group['name'] == root_deployment_name.capitalize }
        expect(generated_groups).not_to be_empty
      end

      it 'generates CF variables available for post-deploy' do
        cf_push_params = generated_pipeline['jobs']
          .flat_map { |job| job['plan'] }
          .select { |step| step['task'] && step['task'].start_with?("push")  }
          .flat_map { |step| step['params'] }
        cf_push_params.each do |task_params|
          expect(task_params).to include('CF_API_URL', 'CF_ORG', 'CF_SPACE', 'CF_USERNAME', 'CF_PASSWORD')
        end
      end
    end
  end
end
