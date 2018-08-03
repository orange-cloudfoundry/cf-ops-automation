require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../task_spec_helper'

describe 'generate-all-manifest task' do
  context 'when environment variables are valid' do
    let(:template_pipelines_dir_content) { Dir["#{@root_dir}/concourse/pipelines/template/*.erb"] }
    let(:expected_pipelines) { template_pipelines_dir_content.map { |filename| File.basename(filename) } }


    before(:context) do
      @root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
      reference_dataset = File.join(@root_dir, 'docs','reference_dataset')
      reference_dataset_template = File.join(reference_dataset, 'template_repository')
      reference_dataset_secrets = File.join(reference_dataset, 'config_repository')
      @templates_dir =  Dir.mktmpdir
      @secrets_dir = Dir.mktmpdir
      @result_dir = Dir.mktmpdir

      FileUtils.cp_r(File.join(reference_dataset_template, '.'), @templates_dir)
      FileUtils.cp_r(File.join(reference_dataset_secrets, '.'), @secrets_dir)

      @output = execute('-c concourse/tasks/generate-all-pipelines.yml ' \
        '-i scripts-resource=. ' \
        "-i templates-resource=#{@templates_dir} " \
        "-i secrets-resource=#{@secrets_dir} " \
        "-o result-dir=#{@result_dir} ",
                        'IAAS_TYPE' => 'task-iaas')
    end

    after(:context) do
      FileUtils.rm_rf @templates_dir
      FileUtils.rm_rf @secrets_dir
      FileUtils.rm_rf @result_dir
    end

    it 'generates expected pipelines' do
      generated_pipeline_filenames = @output.scan(/^processing ..concourse.pipelines.template.(.*\w+)/).flatten
      expect(generated_pipeline_filenames).to match_array(expected_pipelines)
    end

    it 'runs successfully' do
      expect(@output).to end_with("succeeded\n")
    end
  end

  context 'Pre-requisite' do
    let(:task) { YAML.load_file 'concourse/tasks/generate-all-pipelines.yml' }

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
