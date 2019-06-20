require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../task_spec_helper'

describe 'COA upgrade task' do
  let(:yaml_files) { File.join('**', '*.yml') }
  let(:stderr_path) { File.join(@upgrate_results, 'stderr.log') }
  let(:stderr_loaded_file) do
    content = File.read(stderr_path) if File.exist?(stderr_path)
    content || ''
  end

  before(:context) do
    @root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    reference_dataset = File.join(@root_dir, 'docs','reference_dataset')
    reference_dataset_template = File.join(reference_dataset, 'template_repository')
    reference_dataset_secrets = File.join(reference_dataset, 'config_repository')

    @templates_dir =  Dir.mktmpdir
    @config_dir = Dir.mktmpdir
    @upgrated_templates_dir = Dir.mktmpdir
    @upgrated_config_dir = Dir.mktmpdir
    @upgrate_results = Dir.mktmpdir

    FileUtils.cp_r(File.join(reference_dataset_template, '.'), @templates_dir)
    FileUtils.cp_r(File.join(reference_dataset_secrets, '.'), @config_dir)
    @fly_upgrade_cmd = '-c concourse/tasks/coa-upgrade/task.yml ' \
        '-i cf-ops-automation=. ' \
        "-i templates=#{@templates_dir} " \
        "-i config=#{@config_dir} " \
        "-o upgraded-config=#{@upgrated_config_dir} " \
        "-o upgraded-templates=#{@upgrated_templates_dir} " \
        "-o upgrade-results=#{@upgrate_results} "
  end

  after(:context) do
    FileUtils.rm_rf @templates_dir
    FileUtils.rm_rf @config_dir
    FileUtils.rm_rf @upgrated_templates_dir
    FileUtils.rm_rf @upgrated_config_dir
    FileUtils.rm_rf @upgrate_results
  end

  context 'when upgrade version is not defined' do
    before(:context) do
      @output = execute(@fly_upgrade_cmd)
    end

    it 'generates files in config dir' do
      expect(Dir[File.join(@upgrated_config_dir), yaml_files]&.length).to be > 1
    end

    it 'generates files in templates dir' do
      expect(Dir[File.join(@upgrated_templates_dir), yaml_files]&.length).to be > 1
    end

    it 'contains error messages' do
      error_message = @output.scan(/No migration scripts found at/)
      expect(error_message).not_to be_empty
    end
  end

  context 'when running v2.0.0 migration' do
    before(:context) do
      @output = execute(@fly_upgrade_cmd,
                        'COA_VERSION' => '2.0.0')
    end

    it 'generates no errors' do
      expect(stderr_loaded_file).to eq('')
    end

    it 'runs successfully' do
      expect(@output).to match("\nsucceeded\n")
    end
  end

  context 'when running v2.2.0 migration' do
    before(:context) do
      @output = execute(@fly_upgrade_cmd,
                        'COA_VERSION' => '2.2.0')
    end

    it 'generates no errors' do
      expect(stderr_loaded_file).to eq('')
    end

    it 'runs successfully' do
      expect(@output).to match("\nsucceeded\n")
    end
  end

  context 'when running v3.0.0 migration' do
    before(:context) do
      @output = execute(@fly_upgrade_cmd,
                        'COA_VERSION' => '3.0.0')
    end

    it 'generates no errors' do
      expect(stderr_loaded_file).to eq('')
    end

    it 'runs successfully' do
      expect(@output).to match("\nsucceeded\n")
    end
  end
end
