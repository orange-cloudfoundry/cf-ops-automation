require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'template_processor'
require 'ci_deployment'
require 'deployment_deployers_config'
require 'pipeline_generator'

describe TemplateProcessor do
  let(:root_deployment_name) { 'my_depls' }
  let(:processor_context) { { 'my_item' => 'good' } }

  describe '#initialize' do
    context 'the root_deployment_name is nil' do
      subject { described_class.new nil }

      it 'raises an exception' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'the config is nil' do
      subject { described_class.new(root_deployment_name, nil) }

      it 'raises an exception' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'the root_deployment_name is empty' do
      subject { described_class.new '' }

      it 'raises an exception' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#process' do
    context 'when no parameter are provided' do
      subject { described_class.new(root_deployment_name) }

      it 'supports nil' do
        all_processed_template = subject.process nil
        expect(all_processed_template.length).to eq(0)
      end

      it 'supports empty string' do
        all_processed_template = subject.process ''
        expect(all_processed_template.length).to eq(0)
      end
    end

    context 'when parameters are valid' do
      # subject { described_class.new root_deployment_name, config, processor_context }

      # output_dir= File.join('/tmp', 'pipelines')
      before(:context) do
        @output_dir = Dir.mktmpdir('generated-pipelines')
        @pipelines_output_dir = File.join(@output_dir, 'pipelines')
        @template_pipeline_name = 'my-template-pipeline.yml.erb'
        @pipelines_dir = Dir.mktmpdir('pipeline-templates')
      end

      let(:config) { { dump_output: true, output_path: @output_dir } }
      let(:yaml_erb_file_content) do
        {
          'resource_types' => [
            {  'name' => 'slack-notification',
               'type' => 'docker-image',
               'source' => { 'repository' => 'elpaasoci/slack-notification-resource' } }
          ],
          'resources' => [],
          'jobs' => [
            {  'name' => '<%= my_item %>' }
          ]
        }.to_yaml
      end

      # before do
      #   File.open(File.join(@pipelines_dir, @template_pipeline_name), 'w') { |file| file.write(yaml_erb_file_content) }
      # end

      context 'processes an erb file without context' do
        subject { described_class.new root_deployment_name }

        # before do
        #   allow(Dir).to receive(:[]).and_return([@template_pipeline_name.to_s])
        #   allow(File).to receive(:read).and_call_original
        #   allow(File).to receive(:read).with(@template_pipeline_name).and_return(yaml_erb_file_content)
        # end

        after(:context) { FileUtils.rm_rf(@output_dir) }

        xit 'raises an exception' do
          expect(Dir).to receive(:[]).with(@pipelines_dir)
          expect(File).to receive(:read).with(@template_pipeline_name)

          expect { subject.process(@pipelines_dir) }.to raise_error(NameError, /undefined local variable or method `my_item/)
        end
      end

      context 'processes an erb file' do
        subject { described_class.new(root_deployment_name, config, processor_context) }

        let(:expected_yaml_file) do
          <<~TEST
            ---
            resource_types:
            - name: slack-notification
              type: registry-image
              source:
                repository: elpaasoci/slack-notification-resource
            resources: []
            jobs:
            - name: "good"
          TEST
        end

        before { @processed_template = subject.process(@pipelines_dir + '/*') }

        # before do
        #   allow(Dir).to receive(:[]).and_return([@template_pipeline_name.to_s])
        #   allow(File).to receive(:read).and_call_original
        #   allow(File).to receive(:read).with(@template_pipeline_name).and_return(yaml_erb_file_content)
        # end

        after(:context) do
          FileUtils.rm_rf(@output_dir)
          FileUtils.rm_rf(@pipelines_dir)
        end

        xit 'generate a valid yaml file' do
          expect(Dir).to receive(:[]).with(@pipelines_dir)
          expect(File).to receive(:read).with(File.join(@pipelines_output_dir, @template_pipeline_name))

          expect(@processed_template.length).to eq(1)
          expect(File.read(File.join(@pipelines_output_dir, @template_pipeline_name))).to eq(expected_yaml_file)
        end

        xit 'generated filename is correct' do
          expect(File).to be_exist(File.join(@pipelines_output_dir, @template_pipeline_name))
        end
      end

      context 'processes an invalid yml erb file' do
        let(:invalid_yaml_erb_file) do
          <<~TEST
            ---
            resource_types:
            -name= slack-notification
            jobs:
                - name: "not good or <%= my_item %>"
          TEST
        end
        let(:expected_yaml_file) do
          <<~TEST
            ---
            resource_types:
            -name= slack-notification
            jobs:
                - name: "not good or good"
          TEST
        end

        # before do
        #   allow(Dir).to receive(:[]).and_return([@template_pipeline_name.to_s])
        #   allow(File).to receive(:read).and_call_original
        #   allow(File).to receive(:read).with(@template_pipeline_name).and_return(invalid_yaml_erb_file)
        # end

        after(:context) { FileUtils.rm_rf(@output_dir) }

        xit 'raise an exception' do
          expect { subject.process(@pipelines_dir) }.to raise_error(Psych::SyntaxError, /could not find expected ':'/)
          expect(File).to be_exist(File.join(@pipelines_output_dir, 'my_depls-my-template-generated.yml'))
        end

        xit 'generated filename is correct' do
          expect(File).to be_exist(File.join(@pipelines_output_dir, 'my_depls-my-template-generated.yml'))
        end

        xit 'generated content is an invalid yaml file' do
          expect(File.read(File.join(@pipelines_output_dir, 'my_depls-my-template-generated.yml'))).to eq(expected_yaml_file)
        end
      end

      context 'when processing all pipelines without dependencies' do
        subject { described_class.new(root_deployment_name, config, processor_context) }

        let(:root_deployment_name) { 'my-root-depls' }
        let(:ops_automation_path) { '.' }
        let(:secrets_dirs_overview) { {} }
        let(:multi_root_version_reference) { {} }
        let(:multi_root_ci_deployments) { {} }
        let(:git_submodules) { {} }
        let(:all_cf_apps) { {} }
        let(:bosh_cert) { BOSH_CERT_LOCATIONS = { root_deployment_name => 'shared/certificate.pem' }.freeze }
        let(:processor_context) do
          { depls: root_deployment_name,
            root_deployments: [root_deployment_name],
            bosh_cert: bosh_cert,
            multi_root_dependencies: all_dependencies,
            multi_root_ci_deployments: multi_root_ci_deployments,
            multi_root_version_reference: multi_root_version_reference,
            git_submodules: git_submodules,
            multi_root_cf_apps: all_cf_apps,
            secrets_dirs_overview: secrets_dirs_overview,
            config: loaded_config,
            ops_automation_path: ops_automation_path }
        end
        let(:all_dependencies) do
          deps_yaml = <<~YAML
          #{root_deployment_name}:
            bosh-bats:
              status: disabled
            maria-db:
              status: disabled
            bui:
              status: disabled
          YAML
          YAML.safe_load(deps_yaml)
        end
        let(:loaded_config) do
          my_config_yaml = <<~YAML
            offline-mode:
              boshreleases: true
              stemcells: true
              docker-images: false
            precompile-mode: false
          YAML
          YAML.safe_load(my_config_yaml)
        end
        let(:config) { { dump_output: true, output_path: @output_dir } }
        let(:processed_templates_reduced) do
          # excludes pipelines with minimal content
          @processed_template.reject { |_, generated_pipeline_name| generated_pipeline_name.end_with?('init-generated.yml') }
            .reject { |_, generated_pipeline_name| generated_pipeline_name.start_with?("#{root_deployment_name}-s3-stemcell-upload-generated.yml") }
            .reject { |_, generated_pipeline_name| generated_pipeline_name.start_with?("#{root_deployment_name}-s3-br-upload-generated.yml") }
            .reject { |_, generated_pipeline_name| generated_pipeline_name.start_with?("#{root_deployment_name}-sync-helper-generated.yml") }
            .reject { |_, generated_pipeline_name| generated_pipeline_name.start_with?("#{root_deployment_name}-generated.yml") }
            .reject { |_, generated_pipeline_name| generated_pipeline_name.start_with?("#{root_deployment_name}-bosh-generated.yml") }
            .reject { |_, generated_pipeline_name| generated_pipeline_name.start_with?("#{root_deployment_name}-k8s-generated.yml") }
        end

        before do
          @pipelines_dir = File.join('concourse', 'pipelines', 'template')
          @processed_template = subject.process(@pipelines_dir + '/*.erb')
        end

        it 'generates an empty pipelines' do
          processed_templates_reduced.each_value do |generated_pipeline_name|
            generated_pipeline = YAML.load_file(File.join(@pipelines_output_dir, generated_pipeline_name), aliases: true)
            generated_jobs = PipelineHelper.to_hashmap(generated_pipeline_name, generated_pipeline['jobs'])
            expected_jobs = PipelineHelper.to_hashmap(generated_pipeline_name, [{ 'name' => 'this-is-an-empty-pipeline' }])
            expect(generated_jobs).to match(expected_jobs)
          end
        end

        it 'does not generate pipelines with resources' do
          processed_templates_reduced.each_value do |generated_pipeline_name|
            generated_pipeline = YAML.load_file(File.join(@pipelines_output_dir, generated_pipeline_name), aliases: true)
            generated_resources = PipelineHelper.to_hashmap(generated_pipeline_name, generated_pipeline['resources'])
            expected_resources = PipelineHelper.to_hashmap(generated_pipeline_name, nil)

            expect(generated_resources).to match(expected_resources)
          end
        end
      end
    end
  end
end

class PipelineHelper
  def self.to_hashmap(key, value)
    { key => value }
  end
end
