require 'spec_helper'
require 'coa/reference_dataset_documentation/docs_config'
require 'coa/reference_dataset_documentation/file_list_writer'
require 'coa/reference_dataset_documentation/readme'
require 'coa/reference_dataset_documentation/tree_writer'
require 'coa/reference_dataset_documentation/utils_writer'

describe Coa::ReferenceDatasetDocumentation::Readme do
  let(:root_deployment_name) { "root_deployment_name" }
  let(:example_type) { "example_type" }
  let(:config_repository) { "config_repo_name" }
  let(:template_repository) { "template_repo_name" }
  let(:path) { "/path/to/living_docs" }
  let(:base_dir) { PROJECT_ROOT_DIR }
  let(:docs_config) do
    Coa::ReferenceDatasetDocumentation::DocsConfig.new(
      root_deployment_name: root_deployment_name,
      config_repo_name: config_repository,
      template_repo_name: template_repository,
      documentation_path: path
    )
  end

  describe "#rewrite_structure_documentation" do
    let(:readme) { described_class.new(docs_config) }
    let(:utils_writer) { Coa::ReferenceDatasetDocumentation::UtilsWriter.new(docs_config) }
    let(:tree_writer) { Coa::ReferenceDatasetDocumentation::TreeWriter.new(docs_config) }
    let(:file_list_writer) { Coa::ReferenceDatasetDocumentation::FileListWriter.new(docs_config) }

    it "writes an intro and uses TreeWriter and FileListWriter for the rest" do
      allow(readme).to receive(:utils_writer).and_return(utils_writer)
      allow(readme).to receive(:tree_writer).and_return(tree_writer)
      allow(readme).to receive(:file_list_writer).and_return(file_list_writer)
      allow(utils_writer).to receive(:cleanup_readme)
      allow(utils_writer).to receive(:write_intro)
      allow(tree_writer).to receive(:perform)
      allow(file_list_writer).to receive(:write)

      readme.rewrite_structure_documentation

      expect(utils_writer).to have_received(:cleanup_readme)
      expect(utils_writer).to have_received(:write_intro)
      expect(tree_writer).to have_received(:perform)
      expect(file_list_writer).to have_received(:write).
        with(config_repo_name:   docs_config.config_repo_name,
             template_repo_name: docs_config.template_repo_name)
    end
  end
end
