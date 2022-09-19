require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../task_spec_helper'
require_relative '../../generated_templates_helper'
require_relative '../../concourse_tasks_helper'

describe 'generate_depls task' do
  let(:error_logfile) { File.join(@concourse_task_helper.result_dir, 'error.log') }
  let(:generate_depls_logfile) { File.join(@concourse_task_helper.result_dir, 'generate-depls.log') }

  context 'when environment variables are valid' do
    let(:static_pipelines) { Dir["#{@root_dir}/concourse/pipelines/*.yml"] }
    let(:static_pipeline_names) { static_pipelines.map { |filename| File.basename(filename) } }
    let(:expected_pipelines) { static_pipelines.concat(templated_pipelines).sort }
    let(:root_deployment) { 'hello-world-root-depls' }
    let(:output_pipeline_filenames) { Dir["#{@concourse_task_helper.result_dir}/concourse/pipelines/*.yml"] }
    let(:generated_pipeline_filenames) { output_pipeline_filenames.filter { |filename| File.basename(filename).start_with?(root_deployment) || File.basename(filename).start_with?('shared') } }
    let(:copied_pipeline_filenames) { output_pipeline_filenames.reject { |filename| File.basename(filename).start_with?(root_deployment) || File.basename(filename).start_with?('shared') } }
    let(:expected_generated_pipelines) { GeneratedTemplatesHelper.new(@root_dir, root_deployment_name: root_deployment).generated_pipelines }

    before(:context) do
      @root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
      @concourse_task_helper = ConcourseTaskHelper.new(skip_reference: true)
      reference_dataset = File.join(@root_dir, 'docs', 'reference_dataset')
      reference_dataset_template = File.join(reference_dataset, 'template_repository')
      reference_dataset_secrets = File.join(reference_dataset, 'config_repository')

      FileUtils.cp_r(File.join(reference_dataset_template, '.'), @concourse_task_helper.templates_dir)
      FileUtils.cp_r(File.join(reference_dataset_secrets, '.'), @concourse_task_helper.secrets_dir)

      @output = execute('-c concourse/tasks/generate_depls/task.yml ' \
        '-i scripts-resource=. ' \
        "-i templates=#{@concourse_task_helper.templates_dir} " \
        "-i secrets=#{@concourse_task_helper.secrets_dir} " \
        "-o result-dir=#{@concourse_task_helper.result_dir} ",
                        'ROOT_DEPLOYMENT' => 'hello-world-root-depls',
                        'IAAS_TYPE' => 'task-iaas',
                        'PROFILES' => 'vault-profile,undefine-profile')
    end

    after(:context) do
      @concourse_task_helper.cleanup
    end

    it 'generates no errors' do
      expect(File).to be_zero(error_logfile)
    end

    it 'generates execution log file' do
      expect(File).to exist(generate_depls_logfile)
    end

    it 'generates expected pipelines' do
      generated_pipelines = generated_pipeline_filenames.filter { |filename| File.size?(filename) }
        .map { |filename| File.basename filename }
      expect(generated_pipelines).to match_array(expected_generated_pipelines)
    end

    it 'copies static pipelines' do
      copied_static_pipelines = copied_pipeline_filenames.filter { |filename| File.size?(filename) }
        .map { |filename| File.basename filename }
      expect(copied_static_pipelines).to match_array(static_pipeline_names)
    end
  end


  context 'when environment variables are missing' do
    before(:context) do
      @concourse_task_helper = ConcourseTaskHelper.new(skip_reference: true)
      @output = execute('-c concourse/tasks/generate_depls/task.yml ' \
        '-i scripts-resource=. ' \
        "-i templates=#{@concourse_task_helper.templates_dir} " \
        "-i secrets=#{@concourse_task_helper.secrets_dir} " \
        "-o result-dir=#{@concourse_task_helper.result_dir} ",
                        'IAAS_TYPE' => '')
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

    it 'contains error messages' do
      missing_vars = @output.scan(/^ERROR: missing environment variable:.*\w+/)

      expect(missing_vars).to include('ERROR: missing environment variable: ROOT_DEPLOYMENT').and \
        include('ERROR: missing environment variable: IAAS_TYPE')
    end

    it 'contains info messages' do
      info_messages = @output.scan(/^INFO: undefined variable:.*\w+/)

      expect(info_messages).to include('INFO: undefined variable: PROFILES - ignoring').and \
        include('INFO: undefined variable: EXCLUDE_PIPELINES - ignoring')
    end
  end
end
