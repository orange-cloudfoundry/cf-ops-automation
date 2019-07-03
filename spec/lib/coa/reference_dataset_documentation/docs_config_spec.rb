require 'spec_helper'
require 'coa/reference_dataset_documentation/docs_config'

describe Coa::ReferenceDatasetDocumentation::DocsConfig do
  let(:root_deployment_name) { "root_deployment_name" }
  let(:config_repository) { "config_repo_name" }
  let(:template_repository) { "template_repo_name" }
  let(:path) { "/path/to/living_docs" }
  let(:docs_config) do
    described_class.new(
      root_deployment_name: root_deployment_name,
      config_repo_name: config_repository,
      template_repo_name: template_repository,
      documentation_path: path
    )
  end

  describe "#config_repo_path" do
    it "return the path of the config repo" do
      expect(docs_config.config_repo_path).to eq("/path/to/living_docs/#{config_repository}")
    end
  end

  describe "#template_repo_path" do
    it "return the path of the template repo" do
      expect(docs_config.template_repo_path).to eq("/path/to/living_docs/#{template_repository}")
    end
  end

  describe ".cleanup_generated_pipelines" do
    let(:pipelines_base_output_dir) { Dir.mktmpdir }
    let(:pipelines_output_dir) { File.join(pipelines_base_output_dir, 'pipelines') }
    let(:dummy_generated_pipeline) { File.join(pipelines_output_dir, 'dummy-generated.yml') }

    before do
      allow(docs_config).to receive(:documentation_path).and_return(pipelines_base_output_dir)
      Dir.mkdir(pipelines_output_dir)
      FileUtils.touch(dummy_generated_pipeline)
    end

    it "uses rm_rf to delete the pipeline output directory" do
      allow(FileUtils).to receive(:rm_rf)

      described_class.cleanup_generated_pipelines(pipelines_base_output_dir)

      expect(FileUtils).to have_received(:rm_rf).
        with([dummy_generated_pipeline])
    end

    context "when directory does not exist" do
      let(:unknown_pipelines_output_dir) { File.join('tmp', 'unknown_dir') }

      it "uses rm_rf to delete the pipeline output directory" do
        expect {described_class.cleanup_generated_pipelines(unknown_pipelines_output_dir)}
            .to raise_error(Errno::ENOENT, "No such file or directory - #{unknown_pipelines_output_dir}")
      end
    end
  end
end
