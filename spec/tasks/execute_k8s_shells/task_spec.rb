require 'spec_helper'
require 'tmpdir'
require 'yaml'
require 'coa'
require_relative '../task_spec_helper'

describe 'execute_k8s_shells task' do
  context 'when inputs are valid' do
    before(:context) do
      @coa_dir = Dir.mktmpdir
      tasks_dir = File.join('concourse', 'tasks')
      current_task_dir = File.join(tasks_dir, 'execute_k8s_shells')
      FileUtils.mkdir_p(File.join(@coa_dir, tasks_dir), verbose: true)
      FileUtils.cp_r(current_task_dir, File.join(@coa_dir, tasks_dir), verbose: true)
      @pre_processed_manifest = Dir.mktmpdir
      @credentials_dir = Dir.mktmpdir
      @templates_dir = Dir.mktmpdir
      FileUtils.cp_r(File.join(File.dirname(__FILE__), 'templates_dir_fixture', '.'), @templates_dir, verbose: true)
      @k8s_configs_repository = Dir.mktmpdir
      FileUtils.cp_r(File.join(File.dirname(__FILE__), 'k8s_configs_repository_fixture', '.'), @k8s_configs_repository, verbose: true)
      [@templates_dir, @k8s_configs_repository].each do |directory|
        Dir.chdir(directory) do
          `git init .`
          `git add .`
          `git commit -a -m"initial commit"`
          %w[commit_message commit_timestamp committer describe_ref ref short_ref].each do |filename|
            FileUtils.touch(File.join('.git', filename))
          end
        end
      end
      @result_dir = Dir.mktmpdir

      fly_cli_environment = {
          "COA_DEPLOYMENT_NAME" => "my-deployment",
          "CUSTOM_SCRIPT_DIR" => "paas-templates-resource/my-root-depls/my-deployment/my-config",
          "IAAS_TYPE" => "my-iaas",
          "PROFILES" => "p1,p2,p3"
      }
      @output = execute('--include-ignored -c concourse/tasks/execute_k8s_shells/task.yml ' \
        "-i cf-ops-automation=#{@coa_dir} " \
        "-i paas-templates-resource=#{@templates_dir} " \
        "-i credentials-resource=#{@credentials_dir} " \
        "-i pre-processed-manifest=#{@pre_processed_manifest} " \
        "-i k8s-configs-repository=#{@k8s_configs_repository} " \
        "-o result-dir=#{@result_dir} ",\
        fly_cli_environment)
    rescue FlyExecuteError => e
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
    end

    after(:context) do
      FileUtils.rm_rf @pre_processed_manifest
      FileUtils.rm_rf @k8s_configs_repository
      FileUtils.rm_rf @credentials_dir
      FileUtils.rm_rf @coa_dir
      FileUtils.rm_rf @templates_dir
      FileUtils.rm_rf @result_dir
    end

    it 'executes scripts' do
      expected_files = %w[iaas-executed p1-executed p3-executed unnormalized-root-deployment].sort
      expect(Dir.glob('*', base: @result_dir).sort).to match(expected_files)
    end

    it 'does not return any error message' do
      expect(@fly_error).to eq(nil)
    end
  end

  context 'when pre-requisites are valid' do
    let(:task) { YAML.load_file 'concourse/tasks/execute_k8s_shells/task.yml' }

    it 'uses k8s tools image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match(TaskSpecHelper.k8s_tools_image)
    end

    it 'uses a managed k8s tools image version' do
      docker_image_tag_used = task['image_resource']['source']['tag'].to_s
      expect(docker_image_tag_used).to match(TaskSpecHelper.k8s_tools_image_version)
    end

    it 'has inputs' do
      expected_inputs = [{ 'name' => 'paas-templates-resource' }, { "name" => "credentials-resource" }, { "name" => "pre-processed-manifest", "optional" => true }, { 'name' => 'cf-ops-automation' }, { "name" => "k8s-configs-repository" }]
      expect(task['inputs']).to eq(expected_inputs)
    end

    it 'has outputs' do
      expected_outputs = [{ 'name' => 'result-dir' }]
      expect(task['outputs']).to eq(expected_outputs)
    end

    it 'has params' do
      expected_params = {
        "GIT_USER_EMAIL" => "codex.clara-cloud-ops@orange.com",
        "GIT_USER_NAME" => "Orange Cloud Foundry SKC CI Server",
        "TASK_RUN_SCRIPT" => "cf-ops-automation/concourse/tasks/execute_k8s_shells/run.sh",
        "FILE_EXECUTION_FILTER" => "[0-9][0-9]-*.sh",
        "COA_DEPLOYMENT_NAME" => nil,
        "COA_ROOT_DEPLOYMENT_NAME" => nil,
        "CUSTOM_SCRIPT_DIR" => nil,
        "CREDHUB_SERVER" => nil,
        "CREDHUB_CLIENT" => nil,
        "CREDHUB_SECRET" => nil,
        "CREDHUB_CA_CERT" => nil,
        "IAAS_TYPE" => nil,
        "PROFILES" => nil
      }

      expect(task['params']).to eq(expected_params)
    end
  end
end

