require 'spec_helper'
require_relative '../../../lib/reference_dataset_documentation'

describe ReferenceDatasetDocumentation::Generator do
  let(:root_deployment_name) { "root_deployment_name" }
  let(:example_type) { "example_type" }
  let(:config_repository) { "config_repo_name" }
  let(:template_repository) { "template_repo_name" }
  let(:path) { "/path/to/living_docs" }
  let(:base_dir) { ReferenceDatasetDocumentation::PROJECT_ROOT_DIR }

  describe ".new" do
    context "when all required params are provided" do
      let(:params) do
        {
          root_deployment_name: root_deployment_name,
          example_type: example_type,
          config_repo_name: config_repository,
          template_repo_name: template_repository,
          path: path
        }
      end

      it "initializes a new instance" do
        generator = ReferenceDatasetDocumentation::Generator.new(params)

        expect(generator).to be_an_instance_of(ReferenceDatasetDocumentation::Generator)
        expect(generator.path).to eq(File.join(base_dir, path))
      end
    end

    context "when required params are missing" do
      let(:params) do
        {
          root_deployment_name: root_deployment_name,
          example_type: example_type,
          path: path
        }
      end
      let(:error_message) do
        "Provided options incomplete:\nmissing value for param config_repo_name\nmissing value for param template_repo_name"
      end

      it "raise an Argument error with the missing params" do
        expect { ReferenceDatasetDocumentation::Generator.new(params) }.
          to raise_error(ArgumentError, error_message)
      end
    end
  end

  describe "#perform" do
    let(:generator) do
      ReferenceDatasetDocumentation::Generator.new(
        root_deployment_name: root_deployment_name,
        config_repo_name: config_repository,
        template_repo_name: template_repository,
        path: path)
    end

    let(:tree_writer) { ReferenceDatasetDocumentation::TreeWriter.new(generator) }
    let(:file_list_writer) { ReferenceDatasetDocumentation::FileListWriter.new(generator) }

    it "writes an intro and uses TreeWriter and FileListWriter for the rest" do
      expect(File).to receive(:open).with(generator.path, 'w')
      expect(generator).to receive(:add).
        with("# Directory structure '#{root_deployment_name}' for  example", "")

      expect(ReferenceDatasetDocumentation::TreeWriter).to receive(:new).with(generator).
        and_return(tree_writer)
      expect(ReferenceDatasetDocumentation::FileListWriter).to receive(:new).with(generator).
        and_return(file_list_writer)

      expect(tree_writer).to receive(:write_config_repo_tree)
      expect(tree_writer).to receive(:write_template_repo_tree)
      expect(file_list_writer).to receive(:write_config_file_list)
      expect(file_list_writer).to receive(:write_template_file_list)

      generator.perform
    end
  end

  describe "#config_repo_path" do
    let(:generator) do
      ReferenceDatasetDocumentation::Generator.new(
        root_deployment_name: root_deployment_name,
        config_repo_name: config_repository,
        template_repo_name: template_repository,
        path: path)
    end

    it "return the path of the config repo" do
      expect(generator.config_repo_path).to eq("#{base_dir}/docs/reference_dataset/#{config_repository}")
    end
  end

  describe "#template_repo_path" do
    let(:generator) do
      ReferenceDatasetDocumentation::Generator.new(
        root_deployment_name: root_deployment_name,
        config_repo_name: config_repository,
        template_repo_name: template_repository,
        path: path)
    end

    it "return the path of the template repo" do
      expect(generator.template_repo_path).to eq("#{base_dir}/docs/reference_dataset/#{template_repository}")
    end
  end

  describe "#add" do
    let(:generator) do
      ReferenceDatasetDocumentation::Generator.new(
        root_deployment_name: root_deployment_name,
        example_type: example_type,
        config_repo_name: config_repository,
        template_repo_name: template_repository,
        path: path)
    end
    let(:file) { StringIO.new }
    let(:input1) { "foo" }
    let(:input2) { "bar" }

    it "write text in the documentation file" do
      expect(File).to receive(:open).with(generator.path, 'a').
        and_yield(file)
      expect(file).to receive(:puts).with("#{input1}")
      expect(file).to receive(:puts).with("#{input2}")

      generator.add(input1, input2)
    end
  end
end
