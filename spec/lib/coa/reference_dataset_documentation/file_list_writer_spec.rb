require 'spec_helper'
require 'coa/reference_dataset_documentation/file_list_writer'
require 'coa/reference_dataset_documentation/docs_config'

describe Coa::ReferenceDatasetDocumentation::FileListWriter do
  let(:find_answer) { File.read(File.join(File.dirname(__FILE__), 'fixtures/find_answer.txt')) }
  let(:find_root_level_answer) { File.read(File.join(File.dirname(__FILE__), 'fixtures/find_root_level_only_answer.txt')) }
  let(:root_deployment_name) { "root_deployment_name" }
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

  describe "#write" do
    let(:writer) { described_class.new(docs_config) }

    it "write a file list source with Unix's `find`" do
      allow(Dir).to receive(:chdir).
        with(File.join(writer.config_repo_path)).
        and_yield
      allow(Dir).to receive(:chdir).
        with(File.join(writer.template_repo_path)).
        and_yield
      allow(Dir).to receive(:exist?).and_return(true)

      allow(writer).to receive(:`).with("find . -maxdepth 1|sort").
        and_return(find_root_level_answer)
      allow(writer).to receive(:`).with("find #{root_deployment_name}|sort").
        and_return(find_answer)
      allow(writer).to receive(:`).with("find shared|sort").
        and_return(find_answer)

      allow(writer).to receive(:add)

      writer.write(config_repo_name: config_repository, template_repo_name: template_repository)

      expect(writer).to have_received(:`).with("find . -maxdepth 1|sort").twice
      expect(writer).to have_received(:`).with("find #{root_deployment_name}|sort").twice
      expect(writer).to have_received(:`).with("find shared|sort")
    end
  end
end
