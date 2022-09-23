require 'spec_helper'
require 'shared_pipeline_generator'

describe SharedPipelineGenerator do
  describe "#initialize" do
    context "when options are passed" do
      let(:options) { { options: "are present" } }
      let(:pipeline_generator) { described_class.new(options) }

      it "sets the received options" do
        expect(pipeline_generator.options).to eq(OpenStruct.new(options))
      end
    end
  end

  describe "#display_warnings" do
    let(:pipeline_generator) { described_class.new({}) }
    let(:warning1) { "warning1" }
    let(:warning2) { "warning2" }

    it "displays the warnings it contains" do
      pipeline_generator.warnings << warning1
      pipeline_generator.warnings << warning2

      expect { pipeline_generator.display_warnings }.
        to output("#{warning1}\n#{warning2}\n").to_stdout
    end
  end
end

describe SharedPipelineGenerator::PipelineTemplatesFiltering do
  subject { described_class.new(options) }

  let(:options) { OpenStruct.new(ops_automation: '.', input_pipelines: nil, exclude_pipelines: []) }
  let(:pipeline_generator) { described_class.new(options) }
  let(:expected_all_pipelines_templates) do
    coa_current_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    Dir[File.join(coa_current_path, 'concourse', 'pipelines', 'template', '*.yml.erb')].map { |path| path.gsub(coa_current_path, '.') }
  end

  context "when no filter is active" do
    let(:all_pipelines_templates) { subject.filter }

    it 'does not filter any templates' do
      expect(all_pipelines_templates).to match_array(expected_all_pipelines_templates)
    end
  end

  context "when include filter is set" do
    let(:options) { OpenStruct.new(ops_automation: '.', input_pipelines: %w[bosh cf-apps dummy], exclude_pipelines: []) }
    let(:include_templates) { subject.filter }
    let(:expected_include_templates) { %w[./concourse/pipelines/template/bosh-pipeline.yml.erb ./concourse/pipelines/template/cf-apps-pipeline.yml.erb] }

    it 'contains only filtered templates' do
      expect(include_templates).to match_array(expected_include_templates)
    end

    it 'contains 2 elements' do
      expect(include_templates.length).to eq(2)
    end
  end

  context "when exclude filter is set" do
    let(:options) { OpenStruct.new(ops_automation: '.', input_pipelines: [], exclude_pipelines: %w[bosh-pipeline cf-apps-pipeline]) }
    let(:include_templates) { subject.filter }
    let(:expected_excluded_templates) { expected_all_pipelines_templates.reject { |path| path.include?('bosh-pipeline') || path.include?('cf-apps-pipeline') } }

    it 'contains only filtered templates' do
      expect(include_templates).to match_array(expected_excluded_templates)
    end

    it 'contains 2 elements' do
      expect(include_templates.length).to eq(expected_all_pipelines_templates.length - 2)
    end
  end
end
