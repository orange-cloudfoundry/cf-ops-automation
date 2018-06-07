require 'spec_helper'
require_relative '../../../lib/reference_dataset_documentation'

describe ReferenceDatasetDocumentation::Pipelines do
  let(:root_deployment_name) { "root_deployment_name" }
  let(:example_type) { "example_type" }
  let(:config_repository) { "config_repo_name" }
  let(:template_repository) { "template_repo_name" }
  let(:path) { "/path/to/living_docs" }
  let(:base_dir) { ReferenceDatasetDocumentation::PROJECT_ROOT_DIR }
  let(:generator) do
    ReferenceDatasetDocumentation::Generator.new(
      root_deployment_name: root_deployment_name,
      example_type: example_type,
      config_repo_name: config_repository,
      template_repo_name: template_repository,
      path: path)
  end
  let(:secure_random_uuid) { "1234-5678-90ab" }

  describe "#generate" do
    let(:pipelines) { described_class.new(generator) }

    it "calls the generate-depls.rb script to generate pipelines" do
      expect(pipelines).to receive(:`).
        with("ruby #{base_dir}/scripts/generate-depls.rb -o #{pipelines.generated_pipelines_dir} -p #{generator.config_repo_path} -t #{generator.template_repo_path} -d #{generator.root_deployment_name}")

      pipelines.generate
    end
  end

  describe "#are_ok?" do
    let(:pipeline_templates) { ["depls-pipeline.yml.erb", "foo-pipeline.yml.erb"] }
    let(:pipelines) { described_class.new(generator) }

    context "when generated pipelines form the concourse templates are there" do
      it "is true" do
        expect(Dir).to receive(:[]).
          with(File.join(base_dir, 'concourse', 'pipelines', 'template', '*')).
          and_return(pipeline_templates)

        expect(File).to receive(:exist?).
          with("#{pipelines.generated_pipelines_dir}/pipelines/#{generator.root_deployment_name}-generated.yml").
          and_return(true)

        expect(File).to receive(:exist?).
          with("#{pipelines.generated_pipelines_dir}/pipelines/#{generator.root_deployment_name}-foo-generated.yml").
          and_return(true)

        expect(pipelines.are_ok?).to be_truthy
      end
    end

    context "when generated pipelines form the concourse templates are not there" do
      it "is false" do
        expect(Dir).to receive(:[]).
          with(File.join(base_dir, 'concourse', 'pipelines', 'template', '*')).
          and_return(pipeline_templates)

        expect(File).to receive(:exist?).
          with("#{pipelines.generated_pipelines_dir}/pipelines/#{generator.root_deployment_name}-generated.yml").
          and_return(false)

        expect(File).not_to receive(:exist?).
          with("#{pipelines.generated_pipelines_dir}/pipelines/#{generator.root_deployment_name}-foo-generated.yml")

        expect(pipelines.are_ok?).to be_falsy
      end
    end

    describe "#write_pipelines_credential_list" do
      let(:pipelines) { described_class.new(generator) }
      let(:generated_pipelines_dir) { File.join(File.dirname(__FILE__), 'fixtures') }

      it "write the list of required credentials for each pipeline in the docs" do
        expect(generator).to receive(:add).
          with("## Required pipeline credentials for #{generator.root_deployment_name}", "")

        allow(pipelines).to receive(:generated_pipelines_dir).
          and_return(generated_pipelines_dir)

        allow(pipelines.class).to receive(:generated_pipeline_names).
          and_return(['with-creds-', 'with-creds2-', 'without-creds-'])

        expect(generator).to receive(:add).
          with("### #{generator.root_deployment_name}-with-creds-generated.yml", "")
        expect(generator).to receive(:add).with("* mains")
        expect(generator).to receive(:add).with("* face-a-face")
        expect(generator).to receive(:add).with("")

        expect(generator).to receive(:add).
          with("### #{generator.root_deployment_name}-with-creds2-generated.yml", "")
        expect(generator).to receive(:add).with("* mains")
        expect(generator).to receive(:add).with("")

        expect(generator).to receive(:add).
          with("### #{generator.root_deployment_name}-without-creds-generated.yml", "")
        expect(generator).to receive(:add).with("No credentials required", "")

        pipelines.write_pipelines_credential_list
      end
    end

    describe "#write_credentials_pipeline_list" do
      let(:pipelines) { described_class.new(generator) }
      let(:generated_pipelines_dir) { File.join(File.dirname(__FILE__), 'fixtures') }

      it "write the list of pipelines for each credential in the docs" do
        expect(generator).to receive(:add).
          with("## List of pipelines in which credentials appear for #{generator.root_deployment_name}", "")

        allow(pipelines).to receive(:generated_pipelines_dir).
          and_return(generated_pipelines_dir)

        allow(pipelines.class).to receive(:generated_pipeline_names).
          and_return(['with-creds-', 'with-creds2-', 'without-creds-'])

        expect(generator).to receive(:add).
          with("### face-a-face", "")
        expect(generator).to receive(:add).with("* root_deployment_name-with-creds-generated.yml")
        expect(generator).to receive(:add).with("")

        expect(generator).to receive(:add).
          with("### mains", "")
        expect(generator).to receive(:add).with("* root_deployment_name-with-creds-generated.yml")
        expect(generator).to receive(:add).with("* root_deployment_name-with-creds2-generated.yml")
        expect(generator).to receive(:add).with("")

        pipelines.write_credentials_pipeline_list
      end
    end

    describe "#clean" do
      let(:pipelines) { described_class.new(generator) }

      it "uses rm_rf to delete the created directory" do
        expect(FileUtils).to receive(:remove_entry).
          with(pipelines.generated_pipelines_dir)

        pipelines.clean
      end
    end
  end
end

