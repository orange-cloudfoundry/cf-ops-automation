# encoding: utf-8

require 'digest'
require 'yaml'
require 'open3'
require 'rspec'
require_relative '../../../lib/directory_initializer'
require_relative 'test_helper'

# require 'spec_helper.rb'

describe 'generate-depls' do

  # old_path = ENV.fetch('PATH', nil)
  ci_path = Dir.pwd
  test_path = File.join(ci_path, '/spec/scripts/generate-depls')
  # test_reference = File.join(test_path, 'cflinuxfs2-release/blobs')

  # before(:context) do
  #   ENV.store('PATH', "#{test_path}:#{old_path}")
  # end
  #
  # after(:context) do
  #   ENV.store('PATH', old_path)
  # end

  # RSpec.shared_examples 'pipeline checker' do |generated_pipeline_name, reference_pipeline|
  #   it "#{generated_pipeline_name} matches #{reference_pipeline}" do
  #     reference_file = YAML.load_file("#{test_path}/fixtures/references/#{reference_pipeline}")
  #     generated_file = YAML.load_file "#{output_path}/pipelines/#{generated_pipeline_name}"
  #     expect(generated_file).to eq(reference_file)
  #   end
  # end

  #     Dir.chdir("#{ci_path}/spec/tasks/overwrite-cflinuxfs2-release") do

  #     expect(File.exist?(blob_destination)).to eq(true)
  #     expect(File.read(blob_destination)).to eq('new-tarball')
  context 'when no parameter are provided' do
    it 'display help message' do
      stdout_str, stderr_str, status = Open3.capture3("#{ci_path}/scripts/generate-depls.rb")
      expect(status.exitstatus).to eq(1)
      expect(stderr_str).to include("generate-depls: Incomplete/wrong parameter(s): [].\n Usage: ./generate-depls <options>\n    -d, --depls DEPLOYMENT").and include("-t, --templates-path PATH        Base location for paas-templates (implies -s)").and include("-s, --git-submodule-path PATH    .gitsubmodule path").and include("-p, --secrets-path PATH          Base secrets dir (ie: enable-deployment.yml,enable-cf-app.yml, etc...).").and include("-o, --output-path PATH           Output dir for generated pipelines.").and include("-a, --automation-path PATH       Base location for cf-ops-automation").and include("--[no-]dump                  Dump genereted file on standart output")
      expect(stdout_str).to be_empty
    end
  end

  context 'when a dummy deployment is used and output-path is set' do
    let(:depls_name) { 'dummy-depls' }
    let(:output_path) { Dir.mktmpdir }
    let(:templates_path) { Dir.mktmpdir }
    let(:secrets_path) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(output_path) unless output_path.nil?
      FileUtils.rm_rf(templates_path) unless templates_path.nil?
      FileUtils.rm_rf(secrets_path) unless secrets_path.nil?
    end

    context 'when templates dir is empty' do
      let(:options) { "-d #{depls_name} -o #{output_path} -t #{templates_path} -p #{secrets_path}" }

      it 'failed because versions.yml is missing' do
        stdout_str, stderr_str, _ = Open3.capture3( "#{ci_path}/scripts/generate-depls.rb #{options}")
        expect(stderr_str).to include('dummy-depls-versions.yml: file not found')
      end
    end

    context 'when only templates dir is initialized' do
      let(:options) { "-d #{depls_name} -o #{output_path} -t #{templates_path} -p #{secrets_path}" }

      stdout_str = stderr_str = ''
      before do
        initializer = DirectoryInitializer.new depls_name, secrets_path, templates_path
        initializer.setup_templates!
        stdout_str, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")

      end

      it 'generate pipelines without deployment' do
        expect(stderr_str).to eq('')
        expect(stdout_str).to include('### WARNING ### no deployment detected. Please check')
      end


      # context 'when empty pipelines are generated' do
      #   before do
      #     Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
      #   end

      context 'when cf-apps pipeline is checked' do
        it_behaves_like 'pipeline checker', 'dummy-depls-cf-apps-generated.yml', 'empty-cf-apps.yml'
      end

      context 'when depls pipeline is checked' do
        it_behaves_like 'pipeline checker', 'dummy-depls-generated.yml', 'empty-depls.yml'
      end

      context 'when init pipeline is checked' do
        it_behaves_like 'pipeline checker', 'dummy-depls-init-generated.yml', 'empty-init.yml'
      end

      context 'when news pipeline is checked' do
        it_behaves_like 'pipeline checker', 'dummy-depls-news-generated.yml', 'empty-news.yml'
      end

      context 'when sync_helper pipeline is checked' do
        it_behaves_like 'pipeline checker', 'dummy-depls-sync-helper-generated.yml', 'empty-sync-helper.yml'
      end


      # it 'depls pipeline matches reference' do
        #   reference_file = {}#YAML.load "#{}"
        #   generated_file = YAML.load_file "#{output_path}/pipelines/dummy-depls-generated.yml"
        #   expect(generated_file).to eq(reference_file)
        # end
        #
        # it 'sync-helper pipeline matches reference' do
        #   reference_file = {}#YAML.load "#{}"
        #   generated_file = YAML.load_file "#{output_path}/pipelines/dummy-depls-sync-helper-generated.yml"
        #   expect(generated_file).to eq(reference_file)
        # end
      # end
    end
  end
end




