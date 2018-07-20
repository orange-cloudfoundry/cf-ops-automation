# encoding: utf-8

require 'digest'
require 'yaml'
require 'open3'
require 'rspec'
require 'tmpdir'
require_relative 'test_helper'

# require 'spec_helper.rb'

describe 'generate-depls for s3 boshrelease upload pipeline' do

  ci_path = Dir.pwd
  test_path = File.join(ci_path, '/spec/scripts/generate-depls')
  fixture_path = File.join(test_path, '/fixtures')


  context 'when a simple deployment is used' do
    let(:depls_name) { 'simple-depls' }
    let(:output_path) { Dir.mktmpdir }
    let(:templates_path) { "#{fixture_path}/templates" }
    let(:secrets_path) { "#{fixture_path}/secrets" }
    let(:iaas_type) { 'my-custom-iaas' }

    after do
      FileUtils.rm_rf(output_path) unless output_path.nil?
    end

    context 'when valid' do
      let(:options) { "-d #{depls_name} -o #{output_path} -t #{templates_path} -p #{secrets_path} --iaas #{iaas_type} --no-dump -i ./concourse/pipelines/template/s3-br-upload-pipeline.yml.erb" }

      stdout_str = stderr_str = ''
      before do
        stdout_str, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
      end

      it 'no error message are displayed' do
        expect(stderr_str).to eq('')
      end

      it 'only s3-br-upload template is processed' do
        expect(stdout_str).to include('processing ./concourse/pipelines/template/s3-br-upload-pipeline.yml.erb').and \
          include('1 concourse pipeline templates were processed')
      end

      context 'when s3-br-upload pipeline is generated' do
        it_behaves_like 'pipeline checker', 'simple-depls-s3-br-upload-generated.yml', 'simple-depls-s3-br-upload-ref.yml'
      end

    end


  end

end




