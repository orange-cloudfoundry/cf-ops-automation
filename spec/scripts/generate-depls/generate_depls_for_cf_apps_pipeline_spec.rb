require 'digest'
require 'yaml'
require 'open3'
require 'rspec'
require 'tmpdir'
require_relative 'test_helper'

describe 'generate-depls for cf-apps pipeline' do
  let(:ci_path) { Dir.pwd }
  let(:test_path) { File.join(ci_path, '/spec/scripts/generate-depls') }
  let(:fixture_path) { File.join(test_path, '/fixtures') }

  context 'when a simple cf-apps deployment is used' do
    let(:depls_name) { 'apps-depls' }
    let(:output_path) { Dir.mktmpdir }
    let(:templates_path) { "#{fixture_path}/templates" }
    let(:secrets_path) { "#{fixture_path}/secrets" }

    after do
      # FileUtils.rm_rf(output_path) unless output_path.nil?
    end

    context 'when generate-depls is executed' do
      let(:options) { "-d #{depls_name} -o #{output_path} -t #{templates_path} -p #{secrets_path} --no-dump -i ./concourse/pipelines/template/cf-apps-pipeline.yml.erb" }

      stdout_str = stderr_str = ''
      before do
        stdout_str, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
      end

      it 'no error message are displayed' do
        expect(stderr_str).to eq('')
      end

      it 'only cf-apps-pipeline template is processed' do
        expect(stdout_str).to include('processing ./concourse/pipelines/template/cf-apps-pipeline.yml.erb').and \
          include('1 concourse pipeline templates were processed')
      end

      context 'when a generated reference cf-app pipeline file is used' do
        it_behaves_like 'pipeline checker', 'apps-depls-cf-apps-generated.yml', 'apps-depls-cf-apps-ref.yml'
      end
    end
  end

  describe 'cf-apps-pipeline template pre-requisite' do
    context 'when template is processed'
  end

  describe 'multi manifest support' do
    it 'processes all manifests in found in template dir'
  end
end
