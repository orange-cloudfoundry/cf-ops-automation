require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../task_spec_helper'

describe 'generate_concourse_pipeline_config task' do
  let(:pipelines_definitions_file) { File.join(@concourse_pipeline_config, 'pipelines-definitions.yml') }
  let(:expected_pipelines_definitions_content) do
    expected_yaml = <<~YAML
      ---
      pipelines:
      - name: sample-a-generated
        team: main
        config_file: config-resource/coa/pipelines/generated/main/a-root-depls/sample-a-generated.yml
        vars_files:
        - config-resource/coa/config/credentials-one.yml
        - config-resource/coa/config/credentials-two.yml
        - config-resource/coa/config/credentials-sample-a-pipeline.yml
        - templates-resource/a-root-depls/a-root-depls-versions.yml
      - name: sample-b-generated
        team: upload
        config_file: config-resource/coa/pipelines/generated/upload/a-root-depls/sample-b-generated.yml
        vars_files:
        - config-resource/coa/config/credentials-one.yml
        - config-resource/coa/config/credentials-two.yml
        - templates-resource/a-root-depls/a-root-depls-versions.yml
      - name: sync-feature-branches
        team: main
        config_file: config-resource/coa/pipelines/generated/main/a-root-depls/sync-feature-branches.yml
        vars_files:
        - config-resource/coa/config/credentials-one.yml
        - config-resource/coa/config/credentials-two.yml
        - config-resource/coa/config/credentials-sync-feature-branches-pipeline.yml
        - templates-resource/a-root-depls/a-root-depls-versions.yml
    YAML
    YAML.safe_load(expected_yaml)
  end

  context 'when task is executed' do
    before(:context) do
      @concourse_pipeline_config = Dir.mktmpdir
      @coa = Dir.mktmpdir('coa')
      @config_resource = Dir.mktmpdir
      @templates_resource = Dir.mktmpdir

      # With concourse (at least 3.14.1) or our proxy, to avoid error like "Put /volumes/63af0bf8-1570-47a8-62be-4c823867b0b2/stream-in?path=.: unexpected EOF"
      # when tests are executed on local machine, we have to avoid using test datas in current directory, some we copy
      # to a tmp directory before executing tests.
      current_dir = File.dirname(__FILE__)
      FileUtils.cp_r(current_dir + '/../../../concourse', @coa)
      @config_resource_source = File.join(current_dir, 'config-resource')
      @templates_resource_source = File.join(current_dir, 'templates-resource')
      FileUtils.cp_r(@config_resource_source + '/.', @config_resource)
      FileUtils.cp_r(@templates_resource_source + '/.', @templates_resource)

      @output = execute('-c concourse/tasks/generate_concourse_pipeline_config/task.yml ' \
        "-i cf-ops-automation=#{@coa} " \
        "-i config-resource=#{@config_resource} " \
        "-i templates-resource=#{@templates_resource} " \
        "-o concourse-pipeline-config=#{@concourse_pipeline_config} ")
    end

    after(:context) do
      FileUtils.rm_rf @concourse_pipeline_config if File.exist?(@concourse_pipeline_config)
      FileUtils.rm_rf @coa if File.exist?(@coa)
      FileUtils.rm_rf @config_resource if File.exist?(@config_resource)
      FileUtils.rm_rf @templates_resource if File.exist?(@templates_resource)
    end

    it 'success' do
      expect(@output).to match("\nsucceeded\n")
    end

    it 'generates a pipeline definition file' do
      expect(File).to exist(pipelines_definitions_file)
    end

    it 'generates a valid pipeline definition' do
      generated_content = YAML.load_file(pipelines_definitions_file)
      expect(generated_content).to match(expected_pipelines_definitions_content)
    end
  end

  context 'Pre-requisite' do
    let(:task) { YAML.load_file 'concourse/tasks/generate_concourse_pipeline_config/task.yml' }

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
