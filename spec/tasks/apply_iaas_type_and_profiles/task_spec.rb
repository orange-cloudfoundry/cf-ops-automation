require 'spec_helper'
require 'tmpdir'
require 'yaml'
require 'coa'
require_relative '../task_spec_helper'

describe 'apply_iaas_type_and_profiles task' do
  context 'when template repo is valid' do
    before(:context) do
      $stdout = STDOUT
      $stderr = STDERR
      @templates_dir = Dir.mktmpdir
      FileUtils.cp_r(File.join(File.dirname(__FILE__), 'templates_dir_fixture', '.'), @templates_dir, verbose: true)
      @coa_dir = Dir.mktmpdir
      tasks_dir = File.join('concourse', 'tasks')
      current_task_dir = File.join(tasks_dir, 'apply_iaas_type_and_profiles')
      FileUtils.mkdir_p(File.join(@coa_dir, tasks_dir), verbose: true)
      FileUtils.cp_r(current_task_dir, File.join(@coa_dir, tasks_dir), verbose: true)

      Dir.chdir(@templates_dir) do
        `git init .`
        `git branch -m main`
        `git add .`
        `git commit -a -m"initial commit"`
        %w[commit_message commit_timestamp committer describe_ref ref short_ref].each do |filename|
          FileUtils.touch(File.join('.git', filename))
        end
      end
      @result_dir = Dir.mktmpdir

      fly_cli_environment = {
        'PROFILES' => 'Profile1,Profile2',
        'IAAS_TYPE' => 'dummy-iaas',
        'CONFIG_DIR' => 'my-config',
        'COA_DEPLOYMENT_NAME' => 'my-deployment',
        'ROOT_DEPLOYMENT_NAME' => 'my-root-depls'
      }
      @output = execute('--include-ignored -c concourse/tasks/apply_iaas_type_and_profiles/task.yml ' \
        "-i cf-ops-automation=#{@coa_dir} " \
        "-i paas-templates-resource=#{@templates_dir} " \
        "-o paas-templates-resolved=#{@result_dir} ",\
                        fly_cli_environment)
    rescue FlyExecuteError => e
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
    end

    after(:context) do
      FileUtils.rm_rf @templates_dir
      FileUtils.rm_rf @result_dir
      FileUtils.rm_rf @coa_dir
    end
    let(:result_config_dir) { File.join(@result_dir, 'my-root-depls', 'my-deployment', 'my-config') }

    it 'copies iaas and profiles files' do
      expect(File).to exist(File.join(result_config_dir,'iaas-file.yml')).and \
                      exist(File.join(result_config_dir,'p1.yml'))

    end

    it 'does not return any error message' do
      expect(@fly_error).to eq(nil)
    end
  end

  context 'when pre-requisites are valid' do
    let(:task) { YAML.load_file 'concourse/tasks/apply_iaas_type_and_profiles/task.yml' }

    it 'uses k8s tools image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match(TaskSpecHelper.k8s_tools_image)
    end

    it 'uses a managed k8s tools image version' do
      docker_image_tag_used = task['image_resource']['source']['tag'].to_s
      expect(docker_image_tag_used).to match(TaskSpecHelper.k8s_tools_image_version)
    end
  end
end

