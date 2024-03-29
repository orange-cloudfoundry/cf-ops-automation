require 'digest'
require 'yaml'
require 'open3'
require 'rspec'
require 'tmpdir'
require_relative 'test_helper'

describe 'generate-depls for shared control-plane pipeline' do
  let(:ci_path) { Dir.pwd }
  let(:test_path) { File.join(ci_path, '/spec/scripts/generate-depls') }
  let(:fixture_path) { File.join(test_path, '/fixtures') }

  context 'when a simple deployment is used' do
    let(:shared_pipeline) { 'shared' }
    let(:output_path) { Dir.mktmpdir }
    let(:templates_path) { "#{fixture_path}/templates" }
    let(:secrets_path) { "#{fixture_path}/secrets" }
    let(:iaas_type) { 'my-custom-iaas' }
    let(:profiles) { %w[ntp-profile] }

    after do
      FileUtils.rm_rf(output_path) unless output_path.nil?
    end

    context 'when valid' do
      let(:options) { "-o #{output_path} -t #{templates_path} -p #{secrets_path} --iaas #{iaas_type} --no-dump -i control-plane --profiles #{profiles.join(',')}" }

      stdout_str = stderr_str = ''
      before do
        stdout_str, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
      end

      it 'no error message are displayed' do
        expect(stderr_str).to eq('')
      end

      it 'only control-plane template is processed' do
        expect(stdout_str).to include('processing ./concourse/pipelines/shared/control-plane-pipeline.yml.erb').and \
          include('1 concourse pipeline templates were processed')
      end

      context 'when control-plane pipeline is generated' do
        it_behaves_like 'pipeline checker', 'shared-control-plane-generated.yml', 'simple-shared-control-plane.yml'
      end
    end
  end
end
