require 'spec_helper'
require 'concerns/coa_bosh_client'

describe CoaBoshClient do
  let(:config) do
    {
      "client"        => "client",
      "client_secret" => "secret",
      "target"        => "1.1.1.1",
      "environment"   => "1.1.1.1",
      "ca_cert"       => "ca_cert"
    }
  end
  let(:bosh_client) { described_class.new(config) }
  let(:source_profile) do
    [
      "export BOSH_CLIENT='client'",
      "export BOSH_CLIENT_SECRET='secret'",
      "export BOSH_TARGET='1.1.1.1'",
      "export BOSH_ENVIRONMENT='1.1.1.1'",
      "export BOSH_CA_CERT='ca_cert'"
    ].join("\n")
  end
  let(:coa_command_runner) { double(CoaCommandRunner) }

  before do
    allow(CoaCommandRunner).to receive(:new).and_return(coa_command_runner)
    allow(coa_command_runner).to receive(:execute)
  end

  describe '#update_cloud_config' do
    let(:path) { "/path/to/cloud-config.yml" }
    let(:cmd) { "bosh -n update-cloud-config #{path}" }

    it "runs a 'bosh update-cloud-config' command with the provided filepath" do
      bosh_client.update_cloud_config(path)

      expect(CoaCommandRunner).to have_received(:new).
        with(cmd, profile: source_profile)
      expect(coa_command_runner).to have_received(:execute)
    end
  end

  describe '#stemcell_uploaded?' do
    let(:stemcell_name) { "bosh-warden-boshlite-ubuntu-trusty-go_agent" }
    let(:stemcell_version) { "3586.25" }
    let(:cmd) { "bosh stemcells --column name --column version | cut -f1,2" }

    context "when the stemcell is uploaded" do
      let(:command_response) { "bosh-warden-boshlite-ubuntu-trusty-go_agent	3586.25*" }

      it "returns true" do
        allow(coa_command_runner).to receive(:execute).and_return(command_response)

        expect(
          bosh_client.stemcell_uploaded?(stemcell_name, stemcell_version)
        ).to be_truthy

        expect(CoaCommandRunner).to have_received(:new).
          with(cmd, profile: source_profile)
        expect(coa_command_runner).to have_received(:execute)
      end
    end

    context "when the stemcell is not uploaded" do
      let(:command_response) { "bosh-warden-boshlite-ubuntu-xenial-go_agent	70.1*" }

      it "returns true" do
        allow(coa_command_runner).to receive(:execute).and_return(command_response)

        expect(
          bosh_client.stemcell_uploaded?(stemcell_name, stemcell_version)
        ).to be_falsy

        expect(CoaCommandRunner).to have_received(:new).
          with(cmd, profile: source_profile)
        expect(coa_command_runner).to have_received(:execute)
      end
    end
  end
end

