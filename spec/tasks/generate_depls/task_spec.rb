require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../task_spec_helper'

describe 'generate_depls task' do
  let(:error_logfile) { File.join(@result_dir, 'error.log') }
  let(:generate_depls_logfile) { File.join(@result_dir, 'generate-depls.log') }

  context 'when environment variables are valid' do
    let(:static_pipelines) { Dir["#{@root_dir}/concourse/pipelines/*.yml"] }
    let(:static_pipeline_names) { static_pipelines.map { |filename| File.basename(filename) } }
    let(:template_pipelines_dir_content) { Dir["#{@root_dir}/concourse/pipelines/template/*.erb"] }
    let(:template_pipelines) { template_pipelines_dir_content.map { |filename| File.basename(filename) } }
    let(:expected_pipelines) { static_pipelines.concat(templated_pipelines).sort }
    let(:root_deployment) { 'hello-world-root-depls' }
    let(:output_pipeline_filenames) { Dir["#{@result_dir}/concourse/pipelines/*.yml"] }
    let(:generated_pipeline_filenames) { output_pipeline_filenames.filter { |filename| File.basename(filename).start_with?(root_deployment) } }
    let(:copied_pipeline_filenames) { output_pipeline_filenames.reject { |filename| File.basename(filename).start_with?(root_deployment) } }
    let(:expected_generated_pipelines) do
      template_pipelines.map do |name|
        new_name = name.gsub('-pipeline.yml.erb', '-generated.yml')
        root_deployment + '-' + new_name
      end
    end

    before(:context) do
      @root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
      reference_dataset = File.join(@root_dir, 'docs', 'reference_dataset')
      reference_dataset_template = File.join(reference_dataset, 'template_repository')
      reference_dataset_secrets = File.join(reference_dataset, 'config_repository')
      @templates_dir = Dir.mktmpdir
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
                        'IAAS_TYPE' => 'task-iaas',
                        'PROFILES' => 'vault-profile,undefine-profile')
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

  context 'when pipelines generation fails' do
    before(:context) do
      @root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
      reference_dataset = File.join(@root_dir, 'docs', 'reference_dataset')
      reference_dataset_template = File.join(reference_dataset, 'template_repository')
      reference_dataset_secrets = File.join(reference_dataset, 'config_repository')
      @templates_dir = Dir.mktmpdir
      @secrets_dir = Dir.mktmpdir
      @result_dir = Dir.mktmpdir

      FileUtils.cp_r(File.join(reference_dataset_template, '.'), @templates_dir)
      FileUtils.cp_r(File.join(reference_dataset_secrets, '.'), @secrets_dir)
      FileUtils.cp_r(File.join(@secrets_dir, 'hello-world-root-depls/bosh-deployment-sample'), File.join(@secrets_dir, 'hello-world-root-depls/secrets-only-depls'))

      @output = execute('-c concourse/tasks/generate_depls/task.yml ' \
        '-i scripts-resource=. ' \
        "-i templates=#{@templates_dir} " \
        "-i secrets=#{@secrets_dir} " \
        "-o result-dir=#{@result_dir} ",
                        'ROOT_DEPLOYMENT' => 'hello-world-root-depls',
                        'IAAS_TYPE' => 'task-iaas')
    rescue FlyExecuteError => e
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
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

    it 'returns with exit status 1' do
      expect(@fly_status.exitstatus).to eq(1)
    end
  end

  context 'when environment variables are missing' do
    before(:context) do
      @templates_dir = Dir.mktmpdir
      @secrets_dir = Dir.mktmpdir
      @result_dir = Dir.mktmpdir
      @output = execute('-c concourse/tasks/generate_depls/task.yml ' \
        '-i scripts-resource=. ' \
        "-i templates=#{@templates_dir} " \
        "-i secrets=#{@secrets_dir} " \
        "-o result-dir=#{@result_dir} ",
                        'IAAS_TYPE' => '')
    rescue FlyExecuteError => e
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
    end

    after(:context) do
      FileUtils.rm_rf @templates_dir
      FileUtils.rm_rf @secrets_dir
      FileUtils.rm_rf @result_dir
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
