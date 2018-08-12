require 'spec_helper'
require_relative '../../lib/integration_tests'
require_relative '../../lib/concerns/coa_concourse/concourse_client'
require_relative '../../lib/coa_env_bootstrapper/runner'

describe IntegrationTests do
  describe "#run" do
    let(:prereqs_cats) { ["inactive-steps", "concourse"] }
    let(:integration_tests) { IntegrationTests.new(prereqs_paths(prereqs_cats)) }
    let(:concourse) { integration_tests.concourse }

    before do
      allow(CoaConcourse::ConcourseClient).to receive(:new).and_return(concourse)
    end

    it "destroy existing pipelines, bootstrap the COA env and run/watch the pipelines" do
      allow(concourse).to receive(:destroy_pipelines)
      allow(CoaEnvBootstrapper::Runner).to receive(:run_from_prereqs)
      allow(concourse).to receive(:run_and_watch_pipelines)

      integration_tests.run

      expect(concourse).to have_received(:destroy_pipelines).with(described_class::PIPELINES)
      expect(CoaEnvBootstrapper::Runner).to have_received(:run_from_prereqs).with(prereqs_paths(prereqs_cats))
      expect(concourse).to have_received(:run_and_watch_pipelines).with(described_class::PIPELINES, 600)
    end
  end

  describe "#concourse_creds" do
    let(:integration_tests) { IntegrationTests.new(prereqs_paths(prereqs_cats)) }

    context "when values are provided in the 'concourse' prereqs" do
      let(:prereqs_cats) { ["inactive-steps", "concourse"] }
      let(:expected_creds) do
        {
          "target"   => "rspec",
          "url"      => "http://example.com",
          "username" => "concourse_username",
          "password" => "concourse_password",
          "ca_cert"  => "concouse_ca_cert",
          "insecure" => true
        }
      end

      it "builds a hash with those values" do
        expect(integration_tests.concourse_creds).to eq(expected_creds)
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
     File.absolute_path("spec/lib/fixtures/coa_env_bootstrapper/#{category}-prereqs.yml")
  end
end
