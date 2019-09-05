require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../task_spec_helper'

describe 'bosh_delete_plan task' do
  let(:delete_plan) do
    stdout_str, stderr_str, status = Open3.capture3(delete_env, 'concourse/tasks/bosh_delete_plan/run.rb')
    { stdout: stdout_str, stderr: stderr_str, status: status }
  end
  let(:delete_env) { {} }

  context 'when invalid DEPLOYMENTS_TO_DELETE env var' do

    it 'displays an error message' do
      expect(delete_plan[:stderr]).to match(/missing environment variable: DEPLOYMENTS_TO_DELETE/)
    end
  end

  context 'when DEPLOYMENTS_FILE is customized' do
    let(:deployments_to_delete) { Dir.mktmpdir }
    let(:deployments_filename) { 'my_customized_file.txt' }
    let(:deployments_to_delete_list_file) { File.join(deployments_to_delete, deployments_filename) }
    let(:delete_env) { { 'DEPLOYMENTS_TO_DELETE' => 'hello-world', 'DEPLOYMENTS_FILE' => deployments_to_delete_list_file } }

    it 'generates an output file with deployments to delete' do
      delete_plan
      expect(File.read(deployments_to_delete_list_file)).to match('hello-world')
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
      @deployments_to_delete = Dir.mktmpdir

      @output = execute('-c concourse/tasks/bosh_delete_plan/task.yml ' \
        '-i scripts-resource=. ' \
        "-o deployments-to-delete=#{@deployments_to_delete} ",
            'DEPLOYMENTS_TO_DELETE' => '\"hello-world-deployment another-world-deployment\"')
    end

    after(:context) do
      FileUtils.rm_rf @deployments_to_delete if File.exist?(@deployments_to_delete)
    end

    it 'generates a file as result' do
      expect(File).to exist(deployments_to_delete_list_file)
    end

    it 'generates a non empty file' do
      expect(deployments_to_delete_list_file).not_to be_empty
    end

    it 'generates a text file' do
      generated_content = File.read(deployments_to_delete_list_file)
      expect(generated_content).to match(expected_deployments_to_delete_list)
    end

    it 'executes without error' do
      expect(@output).not_to include('failed')
    end
  end

  context 'Pre-requisite' do
    let(:task) { YAML.load_file 'concourse/tasks/bosh_delete_plan/task.yml' }

    it 'uses ruby image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match(TaskSpecHelper.ruby_image)
    end

    it 'uses a managed ruby image version' do
      docker_image_tag_used = task['image_resource']['source']['tag'].to_s
      expect(docker_image_tag_used).to match(TaskSpecHelper.ruby_image_version)
    end
  end
end
