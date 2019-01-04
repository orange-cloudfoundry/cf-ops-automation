require 'spec_helper'
require 'coa/reference_dataset_documentation/docs_config'
require 'coa/reference_dataset_documentation/pipeline_list_writer'

describe Coa::ReferenceDatasetDocumentation::PipelineListWriter do
  let(:root_deployment_name) { "root_deployment_name" }
  let(:config_repository) { "config_repo_name" }
  let(:template_repository) { "template_repo_name" }
  let(:path) { "/path/to/living_docs" }
  let(:docs_config) do
    Coa::ReferenceDatasetDocumentation::DocsConfig.new(
      root_deployment_name: root_deployment_name,
      config_repo_name: config_repository,
      template_repo_name: template_repository,
      documentation_path: generated_pipelines_dir
    )
  end

  let(:generated_pipelines_dir) { File.join(File.dirname(__FILE__), 'fixtures', 'pipelines') }
  let(:generate_pipelines_paths) do
    [
      "#{generated_pipelines_dir}/#{root_deployment_name}-with-creds-generated.yml",
      "#{generated_pipelines_dir}/#{root_deployment_name}-with-creds2-generated.yml",
      "#{generated_pipelines_dir}/#{root_deployment_name}-without-creds-generated.yml"
    ]
  end

  describe "#write_pipelines_credential_list" do
    let(:writer) { described_class.new(docs_config) }

    it "write the list of required credentials for each pipeline in the docs" do
      expect(writer).to receive(:add).
        with("## Required pipeline credentials for #{root_deployment_name}", "")

      allow(writer.pipelines).to receive(:generated_pipeline_paths).
        and_return(generate_pipelines_paths)

      expect(writer).to receive(:add).
        with("### #{writer.root_deployment_name}-with-creds-generated.yml", "")
      expect(writer).to receive(:add).with("* mains")
      expect(writer).to receive(:add).with("* face-a-face")
      expect(writer).to receive(:add).with("")

      expect(writer).to receive(:add).
        with("### #{writer.root_deployment_name}-with-creds2-generated.yml", "")
      expect(writer).to receive(:add).with("* mains")
      expect(writer).to receive(:add).with("")

      expect(writer).to receive(:add).
        with("### #{writer.root_deployment_name}-without-creds-generated.yml", "")
      expect(writer).to receive(:add).with("No credentials required", "")

      writer.write_pipelines_credential_list
    end
  end

  describe "#write_credentials_pipeline_list" do
    let(:writer) { described_class.new(docs_config) }

    it "write the list of pipelines for each credential in the docs" do
      expect(writer).to receive(:add).
        with("## List of pipelines in which credentials appear for #{root_deployment_name}", "")

      allow(writer.pipelines).to receive(:generated_pipeline_paths).
        and_return(generate_pipelines_paths)

      expect(writer).to receive(:add).
        with("### face-a-face", "")
      expect(writer).to receive(:add).with("* root_deployment_name-with-creds-generated.yml")
      expect(writer).to receive(:add).with("")

      expect(writer).to receive(:add).
        with("### mains", "")
      expect(writer).to receive(:add).with("* root_deployment_name-with-creds-generated.yml")
      expect(writer).to receive(:add).with("* root_deployment_name-with-creds2-generated.yml")
      expect(writer).to receive(:add).with("")

      writer.write_credentials_pipeline_list
    end
  end
end
