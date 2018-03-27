# encoding: utf-8

require 'digest'
require 'yaml'
require 'open3'
require 'rspec'
require 'tmpdir'
require_relative 'test_helper'

# require 'spec_helper.rb'

describe 'generate-depls for sync-help pipeline' do

  ci_path = Dir.pwd
  test_path = File.join(ci_path, '/spec/scripts/generate-depls')
  fixture_path = File.join(test_path, '/fixtures')


  context 'when a simple deployment is used' do
    let(:depls_name) { 'simple-depls' }
    let(:output_path) { Dir.mktmpdir }
    let(:templates_path) { "#{fixture_path}/templates" }
    let(:secrets_path) { "#{fixture_path}/secrets" }

    after do
      FileUtils.rm_rf(output_path) unless output_path.nil?
    end

    context 'when valid' do
      let(:options) { "-d #{depls_name} -o #{output_path} -t #{templates_path} -p #{secrets_path} --no-dump -i ./concourse/pipelines/template/sync-helper-pipeline.yml.erb" }

      stdout_str = stderr_str = ''
      before do
        stdout_str, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
      end

      it 'no error message are displayed' do
        expect(stderr_str).to eq('')
      end

      it 'only depls-pipeline template is processed' do
        expect(stdout_str).to include('processing ./concourse/pipelines/template/sync-helper-pipeline.yml.erb').and \
          include('1 concourse pipeline templates were processed')
      end

      context 'when news pipeline is generated' do
        it_behaves_like 'pipeline checker', 'simple-depls-sync-helper-generated.yml', 'simple-depls-sync-helper-ref.yml'
      end

    end


  end

  describe 'news-pipeline template pre-requisite' do
    context 'when template is processed' do

      before do
      end
    end
  end


end




