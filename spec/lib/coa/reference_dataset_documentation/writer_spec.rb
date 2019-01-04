require 'spec_helper'
require 'coa/reference_dataset_documentation/docs_config'
require 'coa/reference_dataset_documentation/writer'

describe Coa::ReferenceDatasetDocumentation::Writer do
  describe "#add" do
    let(:root_deployment_name) { "hello-world-root-depls" }
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
    let(:writer) { described_class.new(docs_config) }
    let(:file) { StringIO.new }
    let(:input1) { "foo" }
    let(:input2) { "bar" }

    it "write text in the documentation file" do
      expect(File).to receive(:open).with(writer.readme_path, 'a').
        and_yield(file)
      expect(file).to receive(:puts).with("#{input1}")
      expect(file).to receive(:puts).with("#{input2}")

      writer.add(input1, input2)
    end
  end
end
