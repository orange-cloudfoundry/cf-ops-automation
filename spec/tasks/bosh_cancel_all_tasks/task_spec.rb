require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../task_spec_helper'

describe 'bosh_tasks_canceller task' do
  let(:error_log) { File.join(@result_dir, 'error.log') }

  context 'when missing environment variables' do
    let(:expected_error_log) do
      <<~TEXT
        ERROR: missing environment variable: BOSH_TARGET
        ERROR: missing environment variable: BOSH_CLIENT
        ERROR: missing environment variable: BOSH_CLIENT_SECRET
        ERROR: missing environment variable: BOSH_CA_CERT
      TEXT
    end

    before(:context) do
      begin
        @config_resource = Dir.mktmpdir
        @result_dir = Dir.mktmpdir
        @root_deployment_name = 'my-big-root-deployment'

        @output = execute('-c concourse/tasks/bosh_cancel_all_tasks/task.yml ' \
        '-i scripts-resource=. ' \
        "-i secrets=#{@config_resource} " \
        "-o result-dir=#{@result_dir} ")
      rescue FlyExecuteError => e
        @output = e.out
        @fly_error = e.err
        @fly_status = e.status
      end
      puts "Fly error message: #{@fly_error}" unless  @fly_status.success?
    end

    after(:context) do
      FileUtils.rm_rf @config_resource if File.exist?(@config_resource)
      FileUtils.rm_rf @result_dir if File.exist?(@result_dir)
    end

    it 'generates an error.log' do
      expect(File.read(error_log)).to match(expected_error_log)
    end

    it 'generates a file as result' do
      expect(File).to exist(error_log)
    end

    it 'generates a non empty file' do
      expect(File.read(error_log)).not_to be_empty
    end

    it 'returns with exit status' do
      expect(@fly_status.exitstatus).to eq(1)
    end
  end

  context 'when pre-requisites are valid' do
    let(:task) { YAML.load_file 'concourse/tasks/bosh_cancel_all_tasks/task.yml' }

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
