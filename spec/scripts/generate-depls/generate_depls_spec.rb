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
      let(:expected_usage) do
        <<~TEXT
         generate-depls: Incomplete/wrong parameter(s): [].
          Usage: ./generate-depls <options>
             -d, --depls ROOT_DEPLOYMENT      Specify a root deployment name to generate template for. MANDATORY
             -t, --templates-path PATH        Base location for paas-templates (implies -s)
             -s, --git-submodule-path PATH    .gitsubmodule path
             -p, --secrets-path PATH          Base secrets dir (i.e. enable-deployment.yml, enable-cf-app.yml, etc.)
             -o, --output-path PATH           Output dir for generated pipelines.
             -a, --automation-path PATH       Base location for cf-ops-automation
             -i, --input PIPELINE1,PIPELINE2  List of pipelines to process without full path and without suffix "-pipeline.yml.erb"
             -e PIPELINE1,PIPELINE2,          List of pipelines to exclude
                 --exclude
                 --[no-]dump                  Dump genereted file on standart output
                 --iaas IAAS_TYPE             Target a specific iaas for pipeline generation
                 --profiles PROFILES          List specific profiles to apply for pipeline generation,separated by "," (e.g. boostrap,feature-a,feature-b)
                 --[no-]profiles-auto-sort    Sort alphabetically profiles. Default: true
        TEXT
      end

      it 'generates shared pipelines' do
        stdout, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb")
        expect(stdout).to include('3 concourse pipeline templates were processed').and \
                          include('shared-control-plane-generated.yml seems a valid Yaml file').and \
                          include('shared-concourse-generated.yml seems a valid Yaml file').and \
                          include('shared-kubernetes-generated.yml seems a valid Yaml file')
      end

      it 'no error message expected' do
        _, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb")
        expect(stderr_str).to eq('')
      end
    end

    context 'when depls parameter is missing' do
      let(:options) { "-o #{output_path} -t #{templates_path} -p #{secrets_path}" }

      it 'generates shared pipelines' do
        stdout, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
        expect(stdout).to include('3 concourse pipeline templates were processed').and \
                          include('shared-control-plane-generated.yml seems a valid Yaml file').and \
                          include('shared-concourse-generated.yml seems a valid Yaml file').and \
                          include('shared-kubernetes-generated.yml seems a valid Yaml file')
      end

      it 'no error message expected' do
        _, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
        expect(stderr_str).to eq('')
      end
    end

    context 'when only a pipeline is selected' do
      let(:depls_name) { 'empty-depls' }
      let(:options) { "-d #{depls_name} -o #{output_path} -t #{templates_path} -p #{secrets_path} -i bosh --no-dump" }

      stdout_str, stderr_str, = ''
      before do
        DirectoryInitializer.new(depls_name, secrets_path, templates_path).setup_templates!
        stdout_str, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
      end

      it 'no error message expected' do
        expect(stderr_str).to eq('')
      end

      it 'only one pipeline template is processed' do
        expect(stdout_str).to include('1 concourse pipeline templates were processed').and include('processing ./concourse/pipelines/template/bosh-pipeline.yml.erb')
      end
    end

    context 'when no dump is set' do
      it 'log output to stdout is reduced'
    end
  end

  context 'when a dummy deployment is used and output-path is set' do
    let(:depls_name) { 'empty-depls' }
    let(:output_path) { Dir.mktmpdir }
    let(:templates_path) { Dir.mktmpdir }
    let(:secrets_path) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(output_path) unless output_path.nil?
      FileUtils.rm_rf(templates_path) unless templates_path.nil?
      FileUtils.rm_rf(secrets_path) unless secrets_path.nil?
    end

    context 'when templates dir is empty' do
      let(:options) { "-d #{depls_name} -o #{output_path} -t #{templates_path}xx -p #{secrets_path}" }

      it 'does not have error' do
        _, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
        expect(stderr_str).to eq('')
      end

      it 'generate empty pipelines' do
        stdout, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
        expect(stdout).to include('4 concourse pipeline templates were processed').and \
                           include('### WARNING ### no deployment detected. Please check').and \
                           include('### WARNING ### no cf app deployment detected. Please check a valid enable-cf-app.yml exists').and \
                           include('### WARNING ### no gitsubmodule detected')
        end
    end

    context 'when only templates dir is initialized' do
      let(:options) { "-d #{depls_name} -o #{output_path} -t #{templates_path} -p #{secrets_path}" }

      stdout_str = stderr_str = ''
      before do
        TestHelper.generate_deployment_bosh_ca_cert(secrets_path)

        initializer = DirectoryInitializer.new depls_name, secrets_path, templates_path
        initializer.setup_templates!
        stdout_str, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}", binmode: true)
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
        it_behaves_like 'pipeline checker', 'empty-depls-cf-apps-generated.yml', 'empty-cf-apps.yml'
      end

      context 'when bosh-precompile pipeline is checked' do
        it_behaves_like 'pipeline checker', 'empty-depls-bosh-precompile-generated.yml', 'empty-bosh-precompile.yml'
      end

      context 'when shared context' do
        let(:options) { "-o #{output_path} -t #{templates_path} -p #{secrets_path}" }

        it 'no error message expected' do
          expect(stderr_str).to eq('')
        end

        it 'generate a pipeline for each shared pipeline template' do
          erb_file_counter = 0
          Dir["#{ci_path}/concourse/pipelines/shared/*.erb"]&.each { erb_file_counter += 1 }
          expect(stdout_str).to include("#{erb_file_counter} concourse pipeline templates were processed")
        end

        context 'when concourse shared pipeline is checked' do
          it_behaves_like 'pipeline checker', 'shared-concourse-generated.yml', 'empty-shared-concourse.yml'
        end

        context 'when k8s shared pipeline is checked' do
          it_behaves_like 'pipeline checker', 'shared-kubernetes-generated.yml', 'empty-shared-kubernetes.yml'
        end
      end
    end
  end
end
