require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../task_spec_helper'

describe 'generate_depls task' do
  context 'when environment variables are valid' do
    let(:static_pipelines) { Dir["#{@root_dir}/concourse/pipelines/*.yml"] }
    let(:template_pipelines) { Dir["#{@root_dir}/concourse/pipelines/template/*.erb"] }
    let(:expected_pipelines) { static_pipelines.concat(templated_pipelines).sort }
    let(:generated_pipeline_filenames) { Dir["#{@result_dir}/concourse/pipelines/*.yml"] }

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

      @output = execute('-c concourse/tasks/generate_depls/task.yml ' \
        '-i scripts-resource=. ' \
        "-i templates=#{@templates_dir} " \
        "-i secrets=#{@secrets_dir} " \
        "-o result-dir=#{@result_dir} ",
                        'ROOT_DEPLOYMENT' => 'hello-world-root-depls',
                        'IAAS_TYPE' => 'task-iaas')
    end

    after(:context) do
      FileUtils.rm_rf @templates_dir
      FileUtils.rm_rf @secrets_dir
      FileUtils.rm_rf @result_dir
    end

    it 'does not generate errors' do
      expect(File).not_to exist(File.join(@result_dir, 'error.log'))
    end

    it 'generates expected pipelines' do
      expect(@output.scan(/^processing ..concourse.pipelines.template.*\w+/).length).to eq(template_pipelines.length)
    end

    it 'runs successfully' do
      expect(@output).to end_with("succeeded\n")
    end
  end

  context 'when environment variables are missing' do

    before(:context) do
      @templates_dir =  Dir.mktmpdir
      @secrets_dir = Dir.mktmpdir
      @result_dir = Dir.mktmpdir
      @output = execute('-c concourse/tasks/generate_depls/task.yml ' \
        '-i scripts-resource=. ' \
        "-i templates=#{@templates_dir} " \
        "-i secrets=#{@secrets_dir} " \
        "-o result-dir=#{@result_dir} ",
                        'IAAS_TYPE' => '')
    end

    after(:context) do
      FileUtils.rm_rf @templates_dir
      FileUtils.rm_rf @secrets_dir
      FileUtils.rm_rf @result_dir
    end

    it 'fails' do
      expect(@output).to end_with("failed\n")
    end

    it 'contains error messages' do
      missing_vars = @output.scan(/^ERROR: missing environment variable:.*\w+/)

      expect(missing_vars).to include('ERROR: missing environment variable: ROOT_DEPLOYMENT').and \
          include('ERROR: missing environment variable: IAAS_TYPE')
    end
  end
end
