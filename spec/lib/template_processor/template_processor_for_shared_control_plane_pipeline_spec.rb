require 'rspec'
require 'fileutils'
require 'tmpdir'

require 'template_processor'
require 'ci_deployment'
require 'deployment_deployers_config'
require 'pipeline_generator'
require_relative 'test_fixtures'

RSpec::Matchers.define_negated_matcher :not_be, :be


describe 'ControlPlanePipelineTemplateProcessing' do
  let(:root_deployment_name) { 'my-root-depls' }
  let(:ops_automation_path) { '.' }
  let(:bosh_cert) { BOSH_CERT_LOCATIONS = { root_deployment_name => 'shared/certificate.pem' }.freeze }
  let(:git_submodules) { {} }
  let(:loaded_config) { {} }
  let(:multi_root_dependencies) {}
  let(:processor_context) do
    { depls: root_deployment_name,
      root_deployments: [root_deployment_name, 'dummy_root_depls'],
      bosh_cert: bosh_cert,
      multi_root_dependencies: multi_root_dependencies,
      multi_root_ci_deployments: multi_root_ci_deployments,
      git_submodules: git_submodules,
      config: loaded_config,
      ops_automation_path: ops_automation_path }
  end
  let(:secrets_dirs_overview) { {} }
  let(:root_deployment_versions) { {} }
  let(:multi_root_ci_deployments) do
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
  let(:expected_groups) do
    [
      { "jobs" => ["*"],
        "name" => "all" },
      {"jobs"=> ["load-generated-pipelines", "manual-reset-avoid-please", "manual-setup", "on-git-commit", "push-changes", "reset-secrets-pipeline-generation", "save-deployed-pipelines"],
       "name"=>"control-plane"},
      {"jobs"=> ["update-pipeline-dummy_root_depls", "update-pipeline-my-root-depls", "update-pipeline-shared"],
       "name"=>"update"},
      { "jobs" => ["update-pipeline-dummy_root_depls"],
        "name" => "dummy_root_depls" },
      { "jobs" => ["update-pipeline-my-root-depls"],
        "name" => "my-root-depls" },
      { "jobs" => ["update-pipeline-shared"],
        "name" => "shared" }
    ]
  end
  let(:groups) { nil }
  let(:expected_meta_resource_type) { Coa::TestFixtures::RESOURCE_TYPES['meta'] }
  let(:expected_slack_notification_resource_type) { Coa::TestFixtures::RESOURCE_TYPES['slack-notification'] }
  let(:update_pipeline_DEPLS_jobs) { generated_pipeline['jobs'].select { |resource| resource['name'].start_with?('update-pipeline-') } }
  let(:update_pipeline_DEPLS_plan) { update_pipeline_DEPLS_jobs.flat_map { |job| job['plan'] } }
  let(:update_pipeline_DEPLS_in_parallel) { update_pipeline_DEPLS_plan.flat_map { |tasks| tasks['in_parallel'] }.compact }

  context 'when processing control-plane-pipeline.yml.erb' do
    subject { TemplateProcessor.new root_deployment_name, config, processor_context }

    before(:context) do
      @output_dir = Dir.mktmpdir('generated-pipelines')
      @pipelines_output_dir = File.join(@output_dir, 'pipelines')
      @template_pipeline_name = 'control-plane-pipeline.yml.erb'
      @pipelines_dir = Dir.mktmpdir('pipeline-templates')

      FileUtils.copy("concourse/pipelines/shared/#{@template_pipeline_name}", @pipelines_dir)
    end

    after(:context) do
      FileUtils.rm_rf(@output_dir)
      FileUtils.rm_rf(@pipelines_dir)
    end

    let(:config) { { dump_output: true, output_path: @output_dir } }
    let(:generated_pipeline) do
      pipeline_template = @processed_template[File.join(@pipelines_dir, @template_pipeline_name)]
      generated_pipeline_path = File.join(@pipelines_output_dir, pipeline_template)
      YAML.load_file(generated_pipeline_path, aliases: true)
    end

    before { @processed_template = subject.process(@pipelines_dir + '/*') }

    context 'when validating resources' do
      let(:expected_meta) { Coa::TestFixtures::RESOURCES['concourse-meta'] }
      let(:expected_slack_notification) { Coa::TestFixtures::RESOURCES['failure-alert'] }
      let(:expected_secrets_depls) do
        secrets = <<~YAML
          name: secrets-limited-for-pipeline
          type: git
          source:
            uri: ((secrets-uri))
            branch: ((secrets-branch))
            skip_ssl_verification: true
            paths: [ "*-depls/ci-deployment-overview.yml", coa/config, "coa/pipelines/generated/**/*-generated.yml", shared, private-config.yml, "*-depls/**/enable-cf-app.yml", "*-depls/**/enable-deployment.yml" ]
        YAML
        YAML.safe_load(secrets)
      end
      let(:expected_secrets_writer) { Coa::TestFixtures::RESOURCES['secrets-writer'] }
      let(:expected_paas_templates_limited) do
        { "icon" => "home-analytics",
          "name" => "paas-templates-limited",
          "source" => {"branch"=>"((paas-templates-branch))", "paths"=>["*-depls/**", ".gitmodules", "shared-config.yml", "meta-inf.yml"], "skip_ssl_verification"=>true, "uri"=>"((paas-templates-uri))" },
          "type" => "git"
        }
      end
      let(:expected_coa) { Coa::TestFixtures::RESOURCES['cf-ops-automation'] }

      it 'generates concourse meta' do
        generated_resource = generated_pipeline['resources'].select { |resource| resource['name'] == 'concourse-meta' }.first
        expect(generated_resource).to match(expected_meta).and not_be(nil)
      end

      it 'generates slack' do
        generated_resource = generated_pipeline['resources'].select { |resource| resource['name'] == 'failure-alert' }.first
        expect(generated_resource).to match(expected_slack_notification) .and not_be(nil)
      end

      it 'generates slack' do
        expected_x = Coa::TestFixtures::RESOURCE_TYPES['slack-notification']
        generated_resource = generated_pipeline['resources'].select { |resource| resource['name'] == 'failure-alert' }.first
        expect(generated_resource).to match(expected_slack_notification) .and not_be(nil)
      end

      it 'generates secrets_DEPLS' do
        generated_resource = generated_pipeline['resources'].select { |resource| resource['name'] == "secrets-limited-for-pipeline" }.first
        expect(generated_resource).to match(expected_secrets_depls).and not_be(nil)
      end

      it 'generates secrets_writer' do
        generated_resource = generated_pipeline['resources'].select { |resource| resource['name'] == 'secrets-writer' }.first
        expect(generated_resource).to match(expected_secrets_writer).and not_be(nil)
      end

      it 'generates paas_templates_limited' do
        generated_resource = generated_pipeline['resources'].select { |resource| resource['name'] == "paas-templates-limited" }.first
        expect(generated_resource).to match(expected_paas_templates_limited).and not_be(nil)
      end

      it 'generates cf_ops_automation' do
        generated_resource = generated_pipeline['resources'].select { |resource| resource['name'] == 'cf-ops-automation' }.first
        expect(generated_resource).to match(expected_coa).and not_be(nil)
      end
    end

    context 'without ci deployment overview' do
      let(:multi_root_ci_deployments) {}

      it 'processes only one template' do
        expect(@processed_template.length).to eq(1)
      end

      it 'processes is not empty' do
        expect(@processed_template).not_to be_empty
      end

      it 'generates a valid yaml file' do
        expect(generated_pipeline).not_to be_falsey
      end

      it 'generates expected number of resource_types' do
        expect(generated_pipeline['resource_types'].length).to eq(4)
      end

      it 'generates groups' do
        current_group = generated_pipeline['groups']
        expect(current_group).to match(expected_groups)
      end
    end

    context 'when validating tasks' do
      let(:expected_generate_DEPLS_pipelines) do
        expected_yaml = <<~YAML
          - task:
            input_mapping: {scripts-resource: cf-ops-automation,templates: paas-templates-<%= depls %>,secrets: secrets-<%= depls %>-for-pipeline}
            output_mapping: {result-dir: concourse-generated-pipeline}
            file: cf-ops-automation/concourse/tasks/generate_depls/task.yml
            params:
              ROOT_DEPLOYMENT: <%= depls %>
              IAAS_TYPE: ((iaas-type))
              EXCLUDE_PIPELINES: depls
              PROFILES: ((profiles))
        YAML
        YAML.safe_load expected_yaml
      end
      let(:expected_generate_DEPLS_pipelines_params) { { 'ROOT_DEPLOYMENT' => root_deployment_name, 'IAAS_TYPE' => '((iaas-type))', 'EXCLUDE_PIPELINES' => 'depls', 'PROFILES' => '((profiles))' } }
      let(:expected_stemcell_deploy_put) { ['((stemcell-main-name))/stemcell.tgz'] * 2 }
      let(:expected_stemcell_init) { 'echo "check-resource -r $BUILD_PIPELINE_NAME/((stemcell-main-name)) --from version:((stemcell-version))" | tee -a result-dir/flight-plan' }

      it 'generates init-concourse-boshrelease-and-stemcell-for-ops-depls' do
        task = update_pipeline_DEPLS_plan
          .select { |step| step['task'] && step['task'] == "generate-#{root_deployment_name}-pipelines" }
          .first
        expect(task['params']).to match(expected_generate_DEPLS_pipelines_params).and not_be(nil)
      end

      it 'generates params for copy-and-filter-generated-pipeline' do
        task = update_pipeline_DEPLS_plan
          .select { |step| step['task'] && step['task'] == "copy-and-filter-generated-pipeline" }
          .first
        expect(task['params']).to match({ 'ROOT_DEPLOYMENT' => root_deployment_name })
      end

      it 'generates params for update-git-generated-pipelines' do
        task = update_pipeline_DEPLS_plan
          .select { |step| step['task'] && step['task'] == "update-git-generated-pipelines" }
          .first
        expect(task['params']).to match({ 'COMMIT_MESSAGE' => "Generated pipelines update for #{root_deployment_name}", 'OLD_DIR' => "coa/pipelines/generated" })
      end

      it 'generates params for update-git-generated-pipelines' do
        task = update_pipeline_DEPLS_plan
          .select { |step| step['task'] && step['task'] == "update-git-generated-pipelines" }
          .first
        expect(task['file']).to match("cf-ops-automation/concourse/tasks/git_append_a_dir_from_generated/task.yml")
      end
    end

    context 'with ci deployment overview' do
      let(:multi_root_ci_deployments) do
        ci_deployments_yaml = <<~YAML
          #{root_deployment_name}:
            target_name: my-concourse-name
            pipelines:
              #{root_deployment_name}-update-generated:
        YAML
        YAML.safe_load ci_deployments_yaml
      end

      it 'generates a meta resource_types' do
        expect(generated_pipeline['resource_types']).to include(expected_meta_resource_type)
      end

      it 'generates a slack_notification resource_types' do
        expect(generated_pipeline['resource_types']).to include(expected_slack_notification_resource_type)
      end

      it 'generates expected number of resource_types' do
        expect(generated_pipeline['resource_types'].length).to eq(4)
      end

      it 'generates groups' do
        current_group = generated_pipeline['groups']
        expect(current_group).to match(expected_groups)
      end
    end

    context 'when validating update-pipeline-hello-world-root-depls triggering' do
      let(:secrets_triggering) { update_pipeline_DEPLS_in_parallel.select { |task| task['get']&.start_with?('secrets-') }.flat_map { |task| task['trigger'] } }
      let(:paas_templates_triggering) { update_pipeline_DEPLS_in_parallel.select { |task| task['get']&.start_with?('paas-templates-') }.flat_map { |task| task['trigger'] } }
      let(:coa_triggering) { update_pipeline_DEPLS_in_parallel.select { |task| task['get']&.start_with?('paas-templates-') }.flat_map { |task| task['trigger'] } }
      let(:concourse_meta_triggering) { update_pipeline_DEPLS_in_parallel.select { |task| task['put']&.start_with?('concourse-meta') }.flat_map { |task| task['trigger'] } }

      it 'triggers automatically on each commit on secrets' do
        expect(secrets_triggering.uniq).to match([true])
      end

      it 'triggers automatically on each commit on paas-templates' do
        expect(paas_templates_triggering.uniq).to match([true])
      end

      it 'triggers automatically on each commit on coa' do
        expect(coa_triggering.uniq).to match([true])
      end

      it 'triggers manually on concourse_meta' do
        expect(concourse_meta_triggering.uniq).to match([false]).or match([nil])
      end
    end

    context 'when validating update-pipeline-hello-world-root-depls config' do
      let(:serials) { update_pipeline_DEPLS_jobs.flat_map { |job| job['serial'] } }
      let(:on_failure) { update_pipeline_DEPLS_jobs.flat_map { |job| job['on_failure'] } }
      let(:expected_on_failure_config) { Coa::TestFixtures::JOB_CONFIG['on_failure'] }

      it 'uses serial mode' do
        expect(serials.uniq).to match([true])
      end

      it 'defines on_failure at job level' do
        expect(on_failure.uniq.first).to match(expected_on_failure_config)
      end
    end

    let(:control_plane_jobs) { generated_pipeline['jobs'] }
    let(:control_plane_resources) { generated_pipeline['resources'] }

    context 'when checking pipelines definition' do
      let(:expected_control_plane_jobs) { %w[load-generated-pipelines manual-reset-avoid-please manual-setup on-git-commit push-changes reset-secrets-pipeline-generation save-deployed-pipelines] }
      let(:expected_update_jobs) { %w[update-pipeline-dummy_root_depls update-pipeline-my-root-depls update-pipeline-shared] }
      let(:expected_jobs) { (expected_control_plane_jobs + expected_update_jobs).sort }

      it 'has expected jobs' do
        jobs = control_plane_jobs.flat_map { |item| item['name'] }.sort
        expect(jobs).to eq(expected_jobs)
      end

      it 'has expected  resources' do
        expected_resources = %w[cf-ops-automation concourse-audit-trail concourse-meta concourse-micro concourse-micro-legacy failure-alert paas-templates-full paas-templates-limited paas-templates-scanned paas-templates-versions secrets-generated-pipelines secrets-limited-for-pipeline secrets-writer]
        resources = control_plane_resources.flat_map { |item| item['name'] }.sort
        expect(resources).to eq(expected_resources)
      end
    end
  end
end
