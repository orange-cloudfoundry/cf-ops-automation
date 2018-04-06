# encoding: utf-8

require 'digest'
require 'yaml'
require 'open3'
require 'rspec'
require 'tmpdir'

# require 'spec_helper.rb'

describe 'reference_dataset' do

  ci_path = Dir.pwd
  stdout_str = stderr_str = ''

  templates_path = 'docs/reference_dataset/template_repository'
  config_path ='docs/reference_dataset/config_repository'
  output_path ='reference_dataset_output_dir'

  before(:all) do
    FileUtils.rm_rf(output_path) unless output_path.nil?
  end

  context 'when bosh_hello_world is used and output-path is set' do
    let(:root_deployment_name) { 'bosh_hello_world' }
    let(:options) { "-d #{root_deployment_name} -o #{output_path} -t #{templates_path} -p #{config_path}" }

    before do
      stdout_str, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
    end

    it 'no error message expected' do
      expect(stderr_str).to eq('')
    end

    it 'generate a pipeline for each pipeline template' do
      erb_file_counter = 0
      Dir["#{ci_path}/concourse/pipelines/template/*.erb"]&.each { erb_file_counter += 1 }
      expect(stdout_str).to include("#{erb_file_counter} concourse pipeline templates were processed")
    end
  end
end
