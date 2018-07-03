require 'spec_helper'
require_relative '../../../lib/reference_dataset_documentation'

describe ReferenceDatasetDocumentation::TreeWriter do
  let(:tree_answer) { File.read(File.join(File.dirname(__FILE__), 'fixtures/tree_answer.txt')) }
  let(:tree_root_level_answer) { File.read(File.join(File.dirname(__FILE__), 'fixtures/tree_root_level_only_answer.txt')) }
  let(:root_deployment_name) { "root_deployment_name" }
  let(:example_type) { "example_type" }
  let(:config_repository) { "config_repo_name" }
  let(:template_repository) { "template_repo_name" }
  let(:path) { "/path/to/living_docs" }
  let(:generator) do
    ReferenceDatasetDocumentation::Generator.new(
      root_deployment_name: root_deployment_name,
      config_repo_name: config_repository,
      template_repo_name: template_repository,
      path: path)
  end

  describe "#perform" do
    let(:tree_writer) { described_class.new(generator) }

    it "write a file list source with Unix's `find`" do
      allow(tree_writer).to receive(:`)
          .and_return(tree_root_level_answer, tree_answer, tree_root_level_answer, tree_answer)
      allow(Dir).to receive(:chdir).
        with(File.join(generator.config_repo_path)).
        and_yield
      allow(Dir).to receive(:chdir).
          with(File.join(generator.template_repo_path)).
          and_yield
      allow(Dir).to receive(:exist?).and_return(true)

      expect(generator).to receive(:add).
        with("## The config repo", "", "### root level overview", "", "```bash", tree_root_level_answer, "```", "")


      expect(generator).to receive(:add).
          with("### #{root_deployment_name} overview", "", "```bash", tree_answer, "```", "").twice



      expect(generator).to receive(:add).
          with("## The template repo", "", "### root level overview", "", "```bash", tree_root_level_answer, "```", "")


      tree_writer.perform
    end
  end
end
