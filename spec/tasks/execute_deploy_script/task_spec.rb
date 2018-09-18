require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../task_spec_helper'

describe 'execute_deploy_script task' do

  context 'when no bosh is available' do

    before(:context) do
      @templates_dir =  Dir.mktmpdir
      @secrets_dir = Dir.mktmpdir
      @result_dir = Dir.mktmpdir

      fly_cli_environment = {
          'BOSH_TARGET' => 'https://dummy-bosh',
          'BOSH_CLIENT' => 'aUser',
          'BOSH_CLIENT_SECRET' => 'aPassword',
          'BOSH_CA_CERT' => 'dummy-cert',
          'CURRENT_DEPLS' => 'xxx',
          'COMMON_SCRIPT_DIR' => 'yyy',
          'SECRETS_DIR' => 'zzz'
      }

      @output = execute('-c concourse/tasks/execute_deploy_script.yml ' \
        '-i scripts-resource=. ' \
        "-i templates=#{@templates_dir} " \
        "-i secrets=#{@secrets_dir} " \
        "-o run-resource=#{@result_dir} ",\
        fly_cli_environment )

    end

    after(:context) do
      FileUtils.rm_rf @templates_dir
      FileUtils.rm_rf @secrets_dir
      FileUtils.rm_rf @result_dir
    end

    it 'tries to login' do
      expect(@output).to include('targeting https://dummy-bosh')
    end

    it 'displays an error message' do
      expect(@output).to include("no address for dummy-bosh")
    end
  end

  context 'when pre-requisites are valid' do
    let(:task) { YAML.load_file 'concourse/tasks/execute_deploy_script.yml' }

    it 'uses alphagov bosh-cli-v2 image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match(TaskSpecHelper.bosh_cli_v2_image)
    end

    it 'uses a managed bosh-cli-v2 image version' do
      docker_image_tag_used = task['image_resource']['source']['tag'].to_s
      expect(docker_image_tag_used).to match(TaskSpecHelper.bosh_cli_v2_image_version)
    end
  end
end
