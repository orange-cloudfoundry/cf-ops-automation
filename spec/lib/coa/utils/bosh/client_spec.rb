require 'spec_helper'
require 'coa/utils/bosh/client'
require 'coa/utils/bosh/config'
require 'coa/utils/command_runner'

describe Coa::Utils::Bosh::Client do
 let(:config) do
    Coa::Utils::Bosh::Config.new(
      "bosh_client"        => "client",
      "bosh_client_secret" => "secret",
      "bosh_target"        => "1.1.1.1",
      "bosh_environment"   => "1.1.1.1",
      "bosh_ca_cert"       => "ca_cert"
    )
  end
  let(:bosh_client) { described_class.new(config) }
  let(:source_profile) do
    [
      "export BOSH_CA_CERT='ca_cert'",
      "export BOSH_CLIENT='client'",
      "export BOSH_CLIENT_SECRET='secret'",
      "export BOSH_ENVIRONMENT='1.1.1.1'",
      "export BOSH_TARGET='1.1.1.1'"
    ].join("\n")
  end
  let(:command_runner) { instance_double("Coa::Utils::CommandRunner") }

  before do
    allow(Coa::Utils::CommandRunner).to receive(:new).and_return(command_runner)
    allow(command_runner).to receive(:execute)
  end

  describe '#update_cloud_config' do
    let(:path) { "/path/to/cloud-config.yml" }
    let(:cmd) { "bosh -n update-cloud-config #{path}" }

    it "runs a 'bosh update-cloud-config' command with the provided filepath" do
      bosh_client.update_cloud_config(path)

      expect(Coa::Utils::CommandRunner).to have_received(:new).
        with(cmd, profile: source_profile)
      expect(command_runner).to have_received(:execute)
    end
  end

  describe '#stemcell_uploaded?' do
    let(:stemcell_name) { "bosh-warden-boshlite-ubuntu-trusty-go_agent" }
    let(:stemcell_version) { "3586.25" }
    let(:cmd) { "bosh stemcells --column name --column version | cut -f1,2" }

    context "when the stemcell is uploaded" do
      let(:command_response) { "bosh-warden-boshlite-ubuntu-trusty-go_agent	3586.25*" }

      it "returns true" do
        allow(command_runner).to receive(:execute).and_return(command_response)

        expect(
          bosh_client.stemcell_uploaded?(stemcell_name, stemcell_version)
        ).to be_truthy

        expect(Coa::Utils::CommandRunner).to have_received(:new).
          with(cmd, profile: source_profile)
        expect(command_runner).to have_received(:execute)
      end
    end

    context "when the stemcell is not uploaded" do
      let(:command_response) { "bosh-warden-boshlite-ubuntu-xenial-go_agent	70.1*" }

      it "returns true" do
        allow(command_runner).to receive(:execute).and_return(command_response)

        expect(
          bosh_client.stemcell_uploaded?(stemcell_name, stemcell_version)
        ).to be_falsy

        expect(Coa::Utils::CommandRunner).to have_received(:new).
          with(cmd, profile: source_profile)
        expect(command_runner).to have_received(:execute)
      end
    end
  end
end

