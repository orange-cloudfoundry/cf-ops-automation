require 'spec_helper'
require 'coa/env_bootstrapper/bootstrapper'
require 'coa/integration_tests'
require 'coa/utils/concourse/concourse'

describe Coa::IntegrationTests::Runner do
  describe "#start" do
    let(:prereqs_cats) { ["inactive-steps", "concourse"] }
    let(:integration_tests) { described_class.new(prereqs_paths(prereqs_cats)) }
    let(:concourse) { integration_tests.concourse }
    let(:fly) { instance_double("Coa::Utils::Concourse::Fly") }
    let(:bootstrapper) { instance_double("Coa::EnvBootstrapper::Bootstrapper") }

    before do
      allow(Coa::Utils::Concourse::Fly).to receive(:new).and_return(fly)
      allow(Coa::Utils::Concourse::Concourse).to receive(:new).and_return(concourse)
      allow(Coa::EnvBootstrapper::Bootstrapper).to receive(:new).and_return(bootstrapper)
    end

    it "destroy existing pipelines, bootstrap the COA env and run/watch the pipelines" do
      allow(concourse).to receive(:destroy_pipelines)
      allow(bootstrapper).to receive(:perform)
      allow(concourse).to receive(:unpause_and_watch_pipelines)

      integration_tests.start

      expect(concourse).to have_received(:destroy_pipelines).with(Coa::IntegrationTests::Constants::PIPELINES)
      expect(bootstrapper).to have_received(:perform)
      expect(concourse).to have_received(:unpause_and_watch_pipelines).with(Coa::IntegrationTests::Constants::PIPELINES)
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
