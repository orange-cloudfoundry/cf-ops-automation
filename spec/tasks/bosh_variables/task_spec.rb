require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../../../concourse/tasks/bosh_cancel_all_tasks/bosh_tasks_canceller.rb'
require_relative '../task_spec_helper'

describe 'bosh_variables task' do
  let(:cancel_all_tasks) do
    stdout_str, stderr_str, status = Open3.capture3(env, 'concourse/tasks/bosh_variables/run.rb')
    { stdout: stdout_str, stderr: stderr_str, status: status }
  end

  context 'when env vars are missing' do
    let(:env) { { "BOSH_TARGET" => nil } }
    it "exits with status 1 and write error in log" do
      expect(cancel_all_tasks[:status].exitstatus).to eq 1
    end
  end

  context 'when executed on concourse' do
    let(:deployments_to_delete_list_file) { File.join(@deployments_to_delete, 'list.txt') }
    let(:expected_deployments_to_delete_list) do
      <<~TEXT
        hello-world-deployment
        another-world-deployment
      TEXT
    end

    before(:context) do
      @result_dir = Dir.mktmpdir
      @secrets_dir = Dir.mktmpdir

      fly_cli_environment = {
          'BOSH_TARGET' => 'https://dummy-bosh',
          'BOSH_CLIENT' => 'aUser',
          'BOSH_CLIENT_SECRET' => 'aPassword',
          'BOSH_DEPLOYMENT' => 'aDeployment',
          'BOSH_CA_CERT' => 'secrets/shared/certs/internal_paas-ca/server-ca.crt'
      }

      @output = execute('-c concourse/tasks/bosh_variables/task.yml ' \
        '-i scripts-resource=. ' \
        "-i secrets=#{@secrets_dir} " \
        "-o result-dir=#{@result_dir} ",
                        fly_cli_environment)
    end

    after(:context) do
      FileUtils.rm_rf @secrets_dir if File.exist?(@secrets_dir)
      FileUtils.rm_rf @result_dir if File.exist?(@result_dir)
    end

    it 'tries to login' do
      expect(@output).to include('targeting https://dummy-bosh')
    end

    it 'displays an error message' do
      expect(@output).to include("no address for dummy-bosh")
    end

    it 'generates an error log file' do
      puts
      expect(File).to exist(File.join(@result_dir,'error.log'))
    end

  end

  context 'when pre-requisites are valid' do
    let(:task) { YAML.load_file 'concourse/tasks/bosh_variables/task.yml' }

    it 'uses ruby image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match(TaskSpecHelper.bosh_cli_v2_image)
    end

    it 'uses a managed ruby image version' do
      docker_image_tag_used = task['image_resource']['source']['tag'].to_s
      expect(docker_image_tag_used).to match(TaskSpecHelper.bosh_cli_v2_image_version)
    end
  end
end

