require 'tmpdir'
require 'open3'
require_relative 'test_helper'
require_relative '../../../lib/directory_initializer'

puts "This should be executed using run_#{File.basename(__FILE__)}"
cleanup_done = false

describe 'generating new reference' do
  ci_path = File.realpath(File.join(File.dirname(__FILE__), '..', '..', '..'))
  test_path = File.join(ci_path, '/spec/scripts/generate-depls')
  fixture_path = File.join(test_path, '/fixtures')

  let(:output_path) { "#{fixture_path}/" }
  let(:templates_path) { "#{fixture_path}/templates" }
  let(:secrets_path) { "#{fixture_path}/secrets" }
  let(:depls_name) { 'simple-depls' }
  let(:iaas_type) { 'my-custom-iaas' }
  let(:include_exclude_pipelines) { "-e cf-apps-pipeline" }
  let(:options) { "--automation-path #{ci_path} -d #{depls_name} -o #{output_path} -t #{templates_path} --profiles ntp-profile -p #{secrets_path} --iaas #{iaas_type} --no-dump #{include_exclude_pipelines}" }

  before do
    unless cleanup_done
      pipelines_dir = File.join(output_path, 'pipelines')
      FileUtils.rm_rf(pipelines_dir) if File.exist?(pipelines_dir)
      cleanup_done = true
    end
    TestHelper.generate_deployment_bosh_ca_cert(secrets_path)
    @stdout_str, @stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
  end

  context 'when processing "simple-depls"' do
    it 'process all pipelines' do
      expect(@stdout_str).to include("9 concourse pipeline templates were processed")
    end

    it 'does not display an error message' do
      expect(@stderr_str).to eq('')
    end
  end

  context 'when processing "delete-depls"' do
    let(:depls_name) { 'delete-depls' }

    it 'process all pipelines' do
      expect(@stdout_str).to include("9 concourse pipeline templates were processed")
    end

    it 'no error message are displayed' do
      expect(@stderr_str).to eq('')
    end
  end

  context 'when processing "empty-depls"' do
    let(:depls_name) { 'empty-depls' }
    let(:templates_path) { Dir.mktmpdir }
    let(:secrets_path) { Dir.mktmpdir }
    let(:include_exclude_pipelines) { "" }

    before do
      TestHelper.generate_deployment_bosh_ca_cert(secrets_path)

      initializer = DirectoryInitializer.new depls_name, secrets_path, templates_path
      initializer.setup_templates!
      @stdout_str, @stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
    end

    it 'process all pipelines' do
      expect(@stdout_str).to include("10 concourse pipeline templates were processed")
    end

    it 'no error message expected' do
      expect(@stderr_str).to eq('')
    end
  end

  context 'when processing "apps-depls"' do
    let(:depls_name) { 'apps-depls' }
    let(:include_exclude_pipelines) { "-i cf-apps" }

    it 'process all pipelines' do
      expect(@stdout_str).to include("1 concourse pipeline templates were processed")
    end

    it 'no error message are displayed' do
      expect(@stderr_str).to eq('')
    end
  end
end
