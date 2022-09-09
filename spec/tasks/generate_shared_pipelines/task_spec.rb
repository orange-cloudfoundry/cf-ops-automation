require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../task_spec_helper'
require_relative '../../generated_templates_helper'
require_relative '../../concourse_tasks_helper'

describe 'generate-shared-manifest task' do
  context 'when environment variables are valid' do
    let(:generated_pipeline_filenames) { Dir["#{@concourse_task_helper.result_dir}/pipelines/*.yml"] }
    let(:expected_generated_pipelines) { GeneratedTemplatesHelper.new(@root_dir,ignore_templates_pipelines: true).generated_pipelines }

    before(:context) do
      @root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
      @concourse_task_helper = ConcourseTaskHelper.new(skip_reference: true)
      reference_dataset = File.join(@root_dir, 'docs', 'reference_dataset')
      reference_dataset_template = File.join(reference_dataset, 'template_repository')
      reference_dataset_secrets = File.join(reference_dataset, 'config_repository')

      FileUtils.cp_r(File.join(reference_dataset_template, '.'), @concourse_task_helper.templates_dir)
      FileUtils.cp_r(File.join(reference_dataset_secrets, '.'), @concourse_task_helper.secrets_dir)

      @output = execute('-c concourse/tasks/generate-shared-pipelines.yml ' \
        '-i scripts-resource=. ' \
        "-i templates-resource=#{@concourse_task_helper.templates_dir} " \
        "-i secrets-resource=#{@concourse_task_helper.secrets_dir} " \
        "-o result-dir=#{@concourse_task_helper.result_dir} ",
                        'IAAS_TYPE' => 'task-iaas')
      rescue FlyExecuteError => e
        @output = e.out
        @fly_error = e.err
        @fly_status = e.status
    end

    after(:context) do
      @concourse_task_helper.cleanup
    end

    it 'does not fail due to fly errors' do
      expect(@fly_error).to be_empty
    end

    it 'generates expected pipelines' do
      generated_pipelines = generated_pipeline_filenames.filter { |filename| File.size?(filename) }
        .map { |filename| File.basename filename }
      expect(generated_pipelines).to match_array(expected_generated_pipelines)
    end
  end

  context 'Pre-requisite' do
    let(:task) { YAML.load_file 'concourse/tasks/generate-shared-pipelines.yml' }

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
