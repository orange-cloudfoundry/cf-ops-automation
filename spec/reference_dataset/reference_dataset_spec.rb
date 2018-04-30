require 'spec_helper'

describe 'reference_dataset' do
  REFERENCE_DATASET_OUTPUT_PATH = 'reference_dataset_output_dir'

  before(:all) do
    FileUtils.rm_rf(REFERENCE_DATASET_OUTPUT_PATH)
  end

  shared_examples "generates valid concourse pipelines" do |root_deployment_name|
    let(:ci_path) { Dir.pwd }
    let(:templates_path) { 'docs/reference_dataset/template_repository/hello-world/' }
    let(:config_path) { 'docs/reference_dataset/config_repository/hello-world/' }
    let(:options) { "-d #{root_deployment_name} -o #{REFERENCE_DATASET_OUTPUT_PATH} -t #{templates_path} -p #{config_path}" }

    # Since the generation happening in the first part of the test is needed
    # to do the validation, we merge this two specs in one
    it "generate a valid pipeline for each pipeline template with no error message" do
      # 1. generation
      templates_count = Dir["#{ci_path}/concourse/pipelines/template/*.erb"].count
      stdout_str, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")

      expect(stderr_str).to eq('')
      expect(stdout_str).to include("#{templates_count} concourse pipeline templates were processed")

      # 2. validation
      Dir["#{ci_path}/concourse/pipelines/template/*.erb"].each do |filepath|
        filename = File.basename(filepath, '-pipeline.yml.erb')
        pipeline_filename = filename == "depls" ? "#{root_deployment_name}-generated.yml" : "#{root_deployment_name}-#{filename}-generated.yml"

        command = "fly validate-pipeline -c ./#{REFERENCE_DATASET_OUTPUT_PATH}/pipelines/#{pipeline_filename} -l ./spec/reference_dataset/fixtures/pipeline-credentials.yml --strict"
        stdout_str, stderr_str, = Open3.capture3(command)
        expect(stderr_str).to be_empty
        expect(stdout_str).to eq "looks good\n"
      end
    end
  end

  context 'for bosh' do
    include_examples "generates valid concourse pipelines", "bosh-sample"
  end

  context 'for concourse' do
    include_examples "generates valid concourse pipelines", "concourse-sample"
  end

  context 'for terraform' do
    include_examples "generates valid concourse pipelines", "terraform-sample"
  end

  context 'for delete-lifecycle' do
    include_examples "generates valid concourse pipelines", "delete-lifecycle-sample"
  end

  context 'for cf-apps' do
    include_examples "generates valid concourse pipelines", "cf-apps-sample"
  end
end
