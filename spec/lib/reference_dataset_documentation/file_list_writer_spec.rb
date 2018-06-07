require 'spec_helper'
require_relative '../../../lib/reference_dataset_documentation'

describe ReferenceDatasetDocumentation::FileListWriter do
  let(:find_answer) { File.read(File.join(File.dirname(__FILE__), 'fixtures/find_answer.txt')) }
  let(:root_deployment_name) { "root_deployment_name" }
  let(:example_type) { "example_type" }
  let(:config_repository) { "config_repo_name" }
  let(:template_repository) { "template_repo_name" }
  let(:path) { "/path/to/living_docs" }
  let(:generator) do
    ReferenceDatasetDocumentation::Generator.new(
      root_deployment_name: root_deployment_name,
      example_type: example_type,
      config_repo_name: config_repository,
      template_repo_name: template_repository,
      path: path)
  end

  describe "#perform" do
    let(:files_writer) { described_class.new(generator) }

    it "write a file list source with Unix's `find`" do
      expect(files_writer).to receive(:`).with("find .").twice.
        and_return(find_answer)
      expect(Dir).to receive(:chdir).
        with(File.join(generator.config_repo_path, root_deployment_name)).
        and_yield
      expect(generator).to receive(:add).
        with("## The config files", "")
      expect(generator).to receive(:add).
        with("* [example-file.yml](/docs/reference_dataset/#{config_repository}/#{example_type}/#{root_deployment_name}/example-file.yml)")
      expect(generator).to receive(:add).
        with("* [example-dir](/docs/reference_dataset/#{config_repository}/#{example_type}/#{root_deployment_name}/example-dir)")
      expect(generator).to receive(:add).
        with("  * [example-file.yml](/docs/reference_dataset/#{config_repository}/#{example_type}/#{root_deployment_name}/example-dir/example-file.yml)")
      expect(generator).to receive(:add).
        with("")

      expect(Dir).to receive(:chdir).
        with(File.join(generator.template_repo_path, root_deployment_name)).
        and_yield
      expect(generator).to receive(:add).
        with("## The template files", "")
      expect(generator).to receive(:add).
        with("* [example-file.yml](/docs/reference_dataset/#{template_repository}/#{example_type}/#{root_deployment_name}/example-file.yml)")
      expect(generator).to receive(:add).
        with("* [example-dir](/docs/reference_dataset/#{template_repository}/#{example_type}/#{root_deployment_name}/example-dir)")
      expect(generator).to receive(:add).
        with("  * [example-file.yml](/docs/reference_dataset/#{template_repository}/#{example_type}/#{root_deployment_name}/example-dir/example-file.yml)")
      expect(generator).to receive(:add).
        with("")

      files_writer.perform
    end
  end
end
