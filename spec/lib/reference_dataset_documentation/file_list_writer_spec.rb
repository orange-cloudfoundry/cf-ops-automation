require 'spec_helper'
require_relative '../../../lib/reference_dataset_documentation'

describe ReferenceDatasetDocumentation::FileListWriter do
  let(:find_answer) { File.read(File.join(File.dirname(__FILE__), 'fixtures/find_answer.txt')) }
  let(:find_root_level_answer) { File.read(File.join(File.dirname(__FILE__), 'fixtures/find_root_level_only_answer.txt')) }
  let(:root_deployment_name) { "hello-world-root-depls" }
  let(:config_repository) { "config_repo_name" }
  let(:template_repository) { "template_repo_name" }
  let(:path) { "/path/to/living_docs" }
  let(:generator) do
    ReferenceDatasetDocumentation::Generator.new(
      root_deployment_name: root_deployment_name,
      config_repo_name: config_repository,
      template_repo_name: template_repository,
      path: path
    )
  end

  describe "#perform" do
    let(:files_writer) { described_class.new(generator) }

    it "write a file list source with Unix's `find`" do
      allow(Dir).to receive(:chdir).
          with(File.join(generator.config_repo_path)).
          and_yield
      allow(Dir).to receive(:chdir).
          with(File.join(generator.template_repo_path)).
          and_yield
      allow(Dir).to receive(:exist?).and_return(true)

      expect(files_writer).to receive(:`).with("find . -maxdepth 1|sort").twice.
        and_return(find_root_level_answer)
      expect(files_writer).to receive(:`).with("find #{root_deployment_name}|sort").twice.
        and_return(find_answer)
      expect(files_writer).to receive(:`).with("find shared|sort").
        and_return(find_answer)

      allow(generator).to receive(:add)


      files_writer.perform
    end
  end
end
