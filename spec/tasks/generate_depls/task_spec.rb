require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../task_spec_helper'

describe 'generate_depls task' do
  let(:error_logfile) { File.join(@result_dir, 'error.log') }
  let(:generate_depls_logfile) { File.join(@result_dir, 'generate-depls.log') }

  context 'when environment variables are valid' do
    let(:static_pipelines) { Dir["#{@root_dir}/concourse/pipelines/*.yml"] }
    let(:template_pipelines_dir_content) { Dir["#{@root_dir}/concourse/pipelines/template/*.erb"] }
    let(:template_pipelines) { template_pipelines_dir_content.map { |filename| File.basename(filename) } }
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

    it 'generates no errors' do
      expect(File).to be_zero(error_logfile)
    end

    it 'generates execution log file' do
      expect(File).to exist(generate_depls_logfile)
    end

    it 'generates expected pipelines' do
      execution_log = File.read(generate_depls_logfile)
      processed_pipeline_templates = execution_log.scan(/^processing ..concourse.pipelines.template.(.*\w+)/).flatten
      expect(processed_pipeline_templates).to match_array(template_pipelines)
    end

    it 'runs successfully' do
      expect(@output).to match("\nsucceeded\n")
    end
  end

  context 'when pipelines generation fails' do

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
      FileUtils.cp_r(File.join(@secrets_dir,'hello-world-root-depls/bosh-deployment-sample'), File.join(@secrets_dir,'hello-world-root-depls/secrets-only-depls'))

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

    it 'generates error log file' do
      expect(File).to exist(error_logfile)
    end

    it 'generates execution log file' do
      expected_log_message = 'Inconsistency detected: deployment <secrets-only-depls> is marked as active'
      error_log = File.read(error_logfile)

      expect(error_log).to include(expected_log_message)
    end

    it 'runs fail' do
      expect(@output).to match("\nfailed\n")
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
      expect(@output).to match("\nfailed\n")
    end

    it 'contains error messages' do
      missing_vars = @output.scan(/^ERROR: missing environment variable:.*\w+/)

      expect(missing_vars).to include('ERROR: missing environment variable: ROOT_DEPLOYMENT').and \
          include('ERROR: missing environment variable: IAAS_TYPE')
    end
  end
end
