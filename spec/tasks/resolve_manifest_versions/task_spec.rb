require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../../../concourse/tasks/resolve_manifest_versions/resolve_manifest_versions'
require_relative '../task_spec_helper'

describe 'resolve_manifest_versions task' do
  context 'when executed on concourse' do
    before(:context) do
      @result_dir = Dir.mktmpdir
      @manifest_dir = Dir.mktmpdir
      @fly_error = ""
      fly_cli_environment = {
          "STEMCELL_NAME" => nil,
          "STEMCELL_VERSION" => nil,
          "MANIFEST_YAML_FILE" => nil,
          "VERSIONS_FILE" => nil
      }

      @output = execute('-c concourse/tasks/resolve_manifest_versions/task.yml ' \
        '-i scripts-resource=. ' \
        "-i templates-resource=#{Dir.mktmpdir} " \
        "-i manifest-dir=#{@manifest_dir} " \
        "-o result-dir=#{@result_dir} ",
                        fly_cli_environment)
        # "-i templates-resource=#{File.join(File.dirname(__FILE__), 'templates_repo')} " \
    rescue FlyExecuteError => e
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
    end

    after(:context) do
      FileUtils.rm_rf @result_dir if File.exist?(@result_dir)
      FileUtils.rm_rf @manifest_dir if File.exist?(@manifest_dir)
    end

    it 'displays warning message' do
      expect(@output).to include("Warning: no manifest detected !")
    end

    it 'does not generate fly error' do
      expect(@fly_error).to eq("")
    end
  end

  context 'when pre-requisites are valid' do
    let(:task) { YAML.load_file 'concourse/tasks/resolve_manifest_versions/task.yml' }

    it 'uses ruby image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match(TaskSpecHelper.bosh_cli_v2_image)
    end

    it 'uses a managed ruby image version' do
      docker_image_tag_used = task['image_resource']['source']['tag'].to_s
      expect(docker_image_tag_used).to match(TaskSpecHelper.bosh_cli_v2_image_version)
    end

    it 'has inputs' do
      expected_inputs = [{ 'name' => 'templates-resource' }, { "name" => "manifest-dir" }, { 'name' => 'scripts-resource' }]
      expect(task['inputs']).to eq(expected_inputs)
    end

    it 'has outputs' do
      expected_outputs = [{ 'name' => 'result-dir' }]
      expect(task['outputs']).to eq(expected_outputs)
    end
    it 'has params' do
      expected_params = { "STEMCELL_NAME" => nil,
                          "STEMCELL_VERSION" => nil,
                          "MANIFEST_YAML_FILE" => nil,
                          "VERSIONS_FILE" => nil }
      expect(task['params']).to eq(expected_params)
    end
  end
end
