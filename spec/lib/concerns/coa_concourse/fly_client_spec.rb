require 'spec_helper'
require 'concerns/coa_concourse/fly_client'
require 'concerns/coa_command_runner'

describe CoaConcourse::FlyClient do
  let(:insecure_creds) { "true" }
  let(:target) { "rspec" }
  let(:creds) do
    {
      "username" => "admin",
      "password" => "secret",
      "insecure" => insecure_creds,
      "url"      => "1.1.1.1",
      "ca_cert"  => "ca_cert"
    }
  end
  let(:runner) { instance_double("CoaCommandRunner") }
  let(:fly) { described_class.new(target, creds) }

  describe '#login' do
    context "without a provided ca_cert" do
      let(:insecure_creds) { "true" }
      let(:expected_cmd) do
        "fly --target #{target} login --username #{creds['username']} \
--password #{creds['password']} --concourse-url #{creds['url']} \
--insecure && fly --target #{target} sync"
      end

      it "logs in in insecure mode" do
        allow(CoaCommandRunner).to receive(:new).and_return(runner)
        allow(runner).to receive(:execute)

        fly.login

        expect(CoaCommandRunner).to have_received(:new).with(expected_cmd, verbose: false)
        expect(runner).to have_received(:execute)
      end
    end

    context "with a provided ca_cert" do
      let(:insecure_creds) { "false" }
      let(:ca_cert) { instance_double("Tempfile") }
      let(:ca_cert_path) { "ca_cert_path" }
      let(:expected_cmd) do
        "fly --target #{target} login --username #{creds['username']} \
--password #{creds['password']} --concourse-url #{creds['url']} \
--ca-cert ca_cert_path && fly --target #{target} sync"
      end

      it "logs in cith ca_cert" do
        allow(Tempfile).to receive(:new).and_return(ca_cert)
        allow(ca_cert).to receive(:write)
        allow(ca_cert).to receive(:close)
        allow(ca_cert).to receive(:path).and_return(ca_cert_path)
        allow(CoaCommandRunner).to receive(:new).and_return(runner)
        allow(runner).to receive(:execute)
        allow(ca_cert).to receive(:unlink)

        fly.login

        expect(Tempfile).to have_received(:new)
        expect(ca_cert).to have_received(:write).with("ca_cert")
        expect(ca_cert).to have_received(:close)
        expect(CoaCommandRunner).to have_received(:new).
          with(expected_cmd, verbose: false)
        expect(runner).to have_received(:execute)
        expect(ca_cert).to have_received(:unlink)
      end
    end

    describe "#destroy_pipelines" do
      let(:pipelines) { { "p1" => { "j1" => {} }, "p2" => { "j1" => {} } } }
      let(:expected_command) { "fly --target #{target} #{command}" }

      it "destroy a list of given pipelines" do
        allow(fly).to receive(:login).twice
        allow(CoaCommandRunner).to receive(:new).and_return(runner)
        allow(runner).to receive(:execute)

        fly.destroy_pipelines(pipelines)

        expect(fly).to have_received(:login).twice
        expect(CoaCommandRunner).to have_received(:new).once.
          with("fly --target #{target} destroy-pipeline --pipeline p1 --non-interactive", {})
        expect(CoaCommandRunner).to have_received(:new).once.
          with("fly --target #{target} destroy-pipeline --pipeline p2 --non-interactive", {})
        expect(runner).to have_received(:execute).twice
      end
    end
  end
end

