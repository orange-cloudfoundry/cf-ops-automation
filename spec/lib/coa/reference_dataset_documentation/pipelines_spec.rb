require 'spec_helper'
require 'coa/constants'
require 'coa/reference_dataset_documentation/pipelines'
require 'coa/reference_dataset_documentation/docs_config'

describe Coa::ReferenceDatasetDocumentation::Pipelines do
  let(:root_deployment_name) { "root_deployment_name" }
  let(:example_type) { "example_type" }
  let(:config_repository) { "config_repo_name" }
  let(:template_repository) { "template_repo_name" }
  let(:path) { "/path/to/living_docs" }
  let(:base_dir) { Coa::Constants::PROJECT_ROOT_DIR }
  let(:docs_config) do
    Coa::ReferenceDatasetDocumentation::DocsConfig.new(
      root_deployment_name: root_deployment_name,
      config_repo_name: config_repository,
      template_repo_name: template_repository,
      documentation_path: path
    )
  end
  let(:secure_random_uuid) { "1234-5678-90ab" }
  let(:output_dir) { docs_config.documentation_path }

  describe "#generate" do
    let(:pipelines) { described_class.new(docs_config) }

    it "calls the generate-depls.rb script to generate pipelines" do
      allow(pipelines).to receive(:`)

      pipelines.generate

      expected_command = "ruby #{base_dir}/scripts/generate-depls.rb -o #{output_dir} -p #{docs_config.config_repo_path} -t #{docs_config.template_repo_path} -d #{root_deployment_name} --iaas openstack --profiles vault-profile"
      expect(pipelines).to have_received(:`).with(expected_command)
    end
  end

  describe "#are_present?" do
    let(:pipeline_templates) { ["bosh-pipeline.yml.erb", "foo-pipeline.yml.erb"] }
    let(:pipelines) { described_class.new(docs_config) }

    context "when generated pipelines form the concourse templates are there" do
      it "is true" do
        expect(Dir).to receive(:[]).
          with(File.join(base_dir, 'concourse', 'pipelines', 'template', '*.yml.erb')).
          and_return(pipeline_templates)

        expect(File).to receive(:exist?).
          with("#{output_dir}/pipelines/#{root_deployment_name}-bosh-generated.yml").
          and_return(true)

        expect(File).to receive(:exist?).
          with("#{output_dir}/pipelines/#{root_deployment_name}-foo-generated.yml").
          and_return(true)

        expect(pipelines).to be_are_present
      end

      context "when generated pipelines form the concourse templates are not there" do
        it "is false" do
          expect(Dir).to receive(:[]).
            with(File.join(base_dir, 'concourse', 'pipelines', 'template', '*.yml.erb')).
            and_return(pipeline_templates)

          expect(File).to receive(:exist?).
            with("#{output_dir}/pipelines/#{root_deployment_name}-bosh-generated.yml").
            and_return(false)

          expect(File).not_to receive(:exist?).
            with("#{output_dir}/pipelines/#{root_deployment_name}-foo-generated.yml")

          expect(pipelines).not_to be_are_present
        end
      end
    end
  end
end
