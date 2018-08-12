require 'spec_helper'
require 'coa/env_bootstrapper/runner'
require 'coa/integration_tests'
require 'coa/utils/concourse/client'

describe Coa::IntegrationTests do
  describe "#run" do
    let(:prereqs_cats) { ["inactive-steps", "concourse"] }
    let(:integration_tests) { described_class.new(prereqs_paths(prereqs_cats)) }
    let(:concourse) { integration_tests.concourse }
    let(:fly) { instance_double("Coa::Utils::Concourse::Fly") }

    before do
      allow(Coa::Utils::Concourse::Fly).to receive(:new).and_return(fly)
      allow(Coa::Utils::Concourse::Client).to receive(:new).and_return(concourse)
    end

    it "destroy existing pipelines, bootstrap the COA env and run/watch the pipelines" do
      allow(concourse).to receive(:destroy_pipelines)
      allow(Coa::EnvBootstrapper::Runner).to receive(:run_from_prereqs)
      allow(concourse).to receive(:run_and_watch_pipelines)

      integration_tests.run

      expect(concourse).to have_received(:destroy_pipelines).with(described_class::PIPELINES)
      expect(Coa::EnvBootstrapper::Runner).to have_received(:run_from_prereqs).with(prereqs_paths(prereqs_cats))
      expect(concourse).to have_received(:run_and_watch_pipelines).with(described_class::PIPELINES, 600)
    end
  end

  describe "#concourse_config" do
    let(:integration_tests) { described_class.new(prereqs_paths(prereqs_cats)) }

    context "when values are provided in the 'concourse' prereqs" do
      let(:prereqs_cats) { ["inactive-steps", "concourse"] }

      it "builds a hash with those values" do
        concourse_config = integration_tests.concourse_config
        expect(concourse_config.target).to eq("rspec")
        expect(concourse_config.insecure).to be_truthy
     end
    end

    context "when values are not provided in the 'concourse' prereqs" do
      let(:prereqs_cats) { ["inactive-steps", "bucc"] }
      it "asks bucc for the values"
    end
  end
end

def prereqs_paths(categories)
  categories.map do |category|
     File.absolute_path("spec/lib/fixtures/coa/env_bootstrapper/#{category}-prereqs.yml")
  end
end
