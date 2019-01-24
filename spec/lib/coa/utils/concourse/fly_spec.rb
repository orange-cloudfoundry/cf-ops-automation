require 'spec_helper'
require 'coa/utils/concourse/config'
require 'coa/utils/concourse/fly'
require 'coa/utils/command_runner'

describe Coa::Utils::Concourse::Fly do
  let(:insecure_creds) { "true" }
  let(:target) { "rspec" }
  let(:team) { "upload" }
  let(:creds) do
    Coa::Utils::Concourse::Config.new(
      "concourse_username" => "admin",
      "concourse_password" => "secret",
      "concourse_insecure" => insecure_creds,
      "concourse_url"      => "1.1.1.1",
      "concourse_ca_cert"  => "ca_cert"
    )
  end
  let(:runner) { instance_double("Coa::Utils::CommandRunner") }

  describe '.login' do
    context "without a provided ca_cert" do
      let(:insecure_creds) { "true" }
      let(:expected_cmd) do
        "fly --target #{target} login --team-name #{team} --username #{creds.username} \
--password #{creds.password} --concourse-url #{creds.url} \
--insecure && fly --target #{target} sync"
      end

      it "logs in in insecure mode" do
        allow(Coa::Utils::CommandRunner).to receive(:new).and_return(runner)
        allow(runner).to receive(:execute)

        described_class.login(target: target, creds: creds, team: team)

        expect(Coa::Utils::CommandRunner).to have_received(:new).with(expected_cmd)
        expect(runner).to have_received(:execute)
      end
    end

    context "with a provided ca_cert" do
      let(:insecure_creds) { "false" }
      let(:ca_cert) { instance_double("Tempfile") }
      let(:ca_cert_path) { "ca_cert_path" }
      let(:expected_cmd) do
        "fly --target #{target} login --team-name #{team} --username #{creds.username} \
--password #{creds.password} --concourse-url #{creds.url} \
--ca-cert ca_cert_path && fly --target #{target} sync"
      end

      it "logs in cith ca_cert" do
        allow(Tempfile).to receive(:new).and_return(ca_cert)
        allow(ca_cert).to receive(:write)
        allow(ca_cert).to receive(:close)
        allow(ca_cert).to receive(:path).and_return(ca_cert_path)
        allow(Coa::Utils::CommandRunner).to receive(:new).and_return(runner)
        allow(runner).to receive(:execute)
        allow(ca_cert).to receive(:unlink)

        described_class.login(target: target, creds: creds, team: team)

        expect(Tempfile).to have_received(:new)
        expect(ca_cert).to have_received(:write).with("ca_cert")
        expect(ca_cert).to have_received(:close)
        expect(Coa::Utils::CommandRunner).to have_received(:new).with(expected_cmd)
        expect(runner).to have_received(:execute)
        expect(ca_cert).to have_received(:unlink)
      end
    end

    describe "#destroy_pipeline" do
      let(:pipeline) { "p1" }
      let(:fly) { described_class.new(target: target, creds: creds) }

      before do
        allow(described_class).to receive(:login)
      end

      it "destroy a list of given pipelines" do
        allow(Coa::Utils::CommandRunner).to receive(:new).and_return(runner)
        allow(runner).to receive(:execute)

        fly.destroy_pipeline(pipeline)

        expect(described_class).to have_received(:login).
          with(target: target, creds: creds, team: "main")
        expect(Coa::Utils::CommandRunner).to have_received(:new).once.
          with("fly --target #{target} destroy-pipeline --pipeline p1 --non-interactive")
      end
    end
  end
end

