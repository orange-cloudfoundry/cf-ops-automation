require 'spec_helper'
require 'open3'
require 'tmpdir'
require 'directory_initializer'
require_relative 'test_helper'

describe 'generate-depls' do
  ci_path = Dir.pwd
  # test_path = File.join(ci_path, '/spec/scripts/generate-depls')
  # old_path = ENV.fetch('PATH', nil)
  # test_reference = File.join(test_path, 'cflinuxfs2-release/blobs')

  # before(:context) do
  #   ENV.store('PATH', "#{test_path}:#{old_path}")
  # end
  #
  # after(:context) do
  #   ENV.store('PATH', old_path)
  # end

  describe 'parameter validation' do
    let(:output_path) { Dir.mktmpdir }
    let(:templates_path) { Dir.mktmpdir }
    let(:secrets_path) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(output_path) unless output_path.nil?
      FileUtils.rm_rf(templates_path) unless templates_path.nil?
      FileUtils.rm_rf(secrets_path) unless secrets_path.nil?
    end

    context 'when no parameter are provided' do
      it 'display help message' do
        stdout_str, stderr_str, status = Open3.capture3("#{ci_path}/scripts/generate-depls.rb")
        expect(status.exitstatus).to eq(1)
        expect(stderr_str).to \
          include('generate-depls: Incomplete/wrong parameter(s): [].').and \
          include("Usage: ./generate-depls <options>\n    -d, --depls ROOT_DEPLOYMENT").and \
          include('-t, --templates-path PATH        Base location for paas-templates (implies -s)').and \
          include('-s, --git-submodule-path PATH    .gitsubmodule path').and \
          include('-p, --secrets-path PATH          Base secrets dir (i.e. enable-deployment.yml, enable-cf-app.yml, etc.)').and \
          include('-o, --output-path PATH           Output dir for generated pipelines.').and \
          include('-a, --automation-path PATH       Base location for cf-ops-automation').and \
          include('-i, --input PIPELINE1,PIPELINE2, List of pipelines to process').and \
          include('--[no-]dump                  Dump genereted file on standart output')
        expect(stdout_str).to be_empty
      end
    end

    context 'when depls parameter is missing' do
      let(:options) { "-o #{output_path} -t #{templates_path} -p #{secrets_path}" }

      it 'an error occurs' do
        _, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
        expect(stderr_str).to include('generate-depls: Incomplete/wrong parameter(s):')
      end

    end

    context 'when only a pipeline is selected' do
      let(:depls_name) { 'dummy-depls' }
      let(:options) { "-d #{depls_name} -o #{output_path} -t #{templates_path} -p #{secrets_path} -i ./concourse/pipelines/template/depls-pipeline.yml.erb --no-dump" }

      stdout_str, stderr_str, = ''
      before do
        DirectoryInitializer.new(depls_name, secrets_path, templates_path).setup_templates!
        stdout_str, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
      end

      it 'no error message expected' do
        expect(stderr_str).to eq('')
      end

      it 'only one pipeline template is processed' do
        expect(stdout_str).to include('1 concourse pipeline templates were processed').and include('processing ./concourse/pipelines/template/depls-pipeline.yml.erb')
      end

    end

    context 'when no dump is set' do
      it 'log output to stdout is reduced'
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
        _, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
        expect(stderr_str).to include('dummy-depls-versions.yml: file not found')
      end
    end

    context 'when only templates dir is initialized' do
      let(:options) { "-d #{depls_name} -o #{output_path} -t #{templates_path} -p #{secrets_path}" }

      stdout_str = stderr_str = ''
      before do
        TestHelper.generate_deployment_bosh_ca_cert(secrets_path)

        initializer = DirectoryInitializer.new depls_name, secrets_path, templates_path
        initializer.setup_templates!
        stdout_str, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
      end

      it 'no error message expected' do
        expect(stderr_str).to eq('')
      end

      it 'generate pipelines without deployment' do
        expect(stdout_str).to include('### WARNING ### no deployment detected. Please check')
      end

      it 'generate a pipeline for each pipeline template' do
        erb_file_counter = 0
        Dir["#{ci_path}/concourse/pipelines/template/*.erb"]&.each { erb_file_counter += 1 }
        expect(stdout_str).to include("#{erb_file_counter} concourse pipeline templates were processed")
      end

      context 'when cf-apps pipeline is empty' do
        it_behaves_like 'pipeline checker', 'dummy-depls-cf-apps-generated.yml', 'empty-cf-apps.yml'
      end

      context 'when depls pipeline is empty' do
        it_behaves_like 'pipeline checker', 'dummy-depls-generated.yml', 'empty-depls.yml'
      end

      context 'when init pipeline is empty' do
        it_behaves_like 'pipeline checker', 'dummy-depls-init-generated.yml', 'empty-init.yml'
      end

      context 'when news pipeline is empty' do
        it_behaves_like 'pipeline checker', 'dummy-depls-news-generated.yml', 'empty-news.yml'
      end

      context 'when sync_helper pipeline is checked' do
        it_behaves_like 'pipeline checker', 'dummy-depls-sync-helper-generated.yml', 'empty-sync-helper.yml'
      end

      context 'when s3-stemcell-upload pipeline is checked' do
        it_behaves_like 'pipeline checker', 'dummy-depls-s3-stemcell-upload-generated.yml', 'empty-s3-stemcell-upload.yml'
      end

      context 'when s3-br-upload pipeline is checked' do
        it_behaves_like 'pipeline checker', 'dummy-depls-s3-br-upload-generated.yml', 'empty-s3-br-upload.yml'
      end

      context 'when concourse pipeline is checked' do
        it_behaves_like 'pipeline checker', 'dummy-depls-concourse-generated.yml', 'empty-concourse.yml'
      end
    end
  end
end




