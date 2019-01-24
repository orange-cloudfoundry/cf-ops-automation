require 'spec_helper'
require 'coa/reference_dataset_documentation/docs_config'
require 'coa/reference_dataset_documentation/tree_writer'

describe Coa::ReferenceDatasetDocumentation::TreeWriter do
  let(:tree_answer) { File.read(File.join(File.dirname(__FILE__), 'fixtures/tree_answer.txt')) }
  let(:tree_root_level_answer) { File.read(File.join(File.dirname(__FILE__), 'fixtures/tree_root_level_only_answer.txt')) }
  let(:root_deployment_name) { "root_deployment_name" }
  let(:example_type) { "example_type" }
  let(:config_repository) { "config_repo_name" }
  let(:template_repository) { "template_repo_name" }
  let(:path) { "/path/to/living_docs" }
  let(:docs_config) do
    Coa::ReferenceDatasetDocumentation::DocsConfig.new(
      root_deployment_name: root_deployment_name,
      config_repo_name: config_repository,
      template_repo_name: template_repository,
      documentation_path: path
    )
  end

  describe "#perform" do
    let(:tree_writer) { described_class.new(docs_config) }

    it "write a file list source with Unix's `find`" do
      allow(tree_writer).to receive(:`)
        .and_return(tree_root_level_answer, tree_answer, tree_root_level_answer, tree_answer)
      allow(Dir).to receive(:chdir).
        with(File.join(tree_writer.config_repo_path)).
        and_yield
      allow(Dir).to receive(:chdir).
        with(File.join(tree_writer.template_repo_path)).
        and_yield
      allow(Dir).to receive(:exist?).and_return(true)

      allow(tree_writer).to receive(:write)

      tree_writer.perform

      expect(tree_writer).to have_received(:write).
        with("## The config repo", "", "### root level overview", "", "```bash", tree_root_level_answer, "```", "")

      expect(tree_writer).to have_received(:write).
        with("### #{root_deployment_name} overview", "", "```bash", tree_answer, "```", "").twice

      expect(tree_writer).to have_received(:write).
        with("## The template repo", "", "### root level overview", "", "```bash", tree_root_level_answer, "```", "")
   end
  end
end
