require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../task_spec_helper'

describe 'bosh_delete_plan task' do
  let(:error_log) { File.join(@delete_result_dir, 'error.log') }

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
      @deployments_to_delete = Dir.mktmpdir
      @secrets = Dir.mktmpdir
      @delete_result_dir = Dir.mktmpdir

      @output = execute('-c concourse/tasks/bosh_delete_apply/task.yml ' \
      '-i scripts-resource=. ' \
      "-i secrets=#{@secrets} " \
      "-o delete-result-dir=#{@delete_result_dir} ")
    end

    after(:context) do
      FileUtils.rm_rf @deployments_to_delete if File.exist?(@deployments_to_delete)
      FileUtils.rm_rf @secrets if File.exist?(@secrets)
      FileUtils.rm_rf @delete_result_dir if File.exist?(@delete_result_dir)
    end

    it 'generates an error.log' do
      expect(File.read(error_log)).to match(expected_error_log)
    end

    it 'generates a file as result' do
      expect(File).to exist(error_log)
    end

    it 'generates a non empty file' do
      expect(error_log).not_to be_empty
    end
  end

  context 'Pre-requisite' do
    let(:task) { YAML.load_file 'concourse/tasks/bosh_delete_apply/task.yml' }

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
