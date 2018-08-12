require 'yaml'
require 'spec_helper'
require 'coa_env_bootstrapper/base'
require 'coa_env_bootstrapper/bosh'

describe CoaEnvBootstrapper::Bosh do
  let(:config_source) do
    {
      "bosh_environment" => "env",
      "bosh_target" => "192.0.0.1",
      "bosh_client" => "admin",
      "bosh_client_secret" => "secr3t",
      "bosh_ca_cert" => ""
    }
  end
  let(:bosh) { described_class.new(config_source) }
  let(:bosh_client) { bosh.bosh_client }

  describe '#upload_stemcell' do
    let(:stemcell_name) { "bosh-warden-boshlite-ubuntu-trusty-go_agent" }
    let(:stemcell_version) { "3586.23" }
    let(:stemcell_uri) { "example.com" }
    let(:stemcell_sha) { "1234abcd" }
    let(:stemcell_config) do
      {
        "name"    => stemcell_name,
        "version" => stemcell_version,
        "uri"     => stemcell_uri,
        "sha"     => stemcell_sha
      }
    end

    context 'when the stemcell is already uploaded' do
      before do
        allow(bosh_client).
          to receive(:stemcell_uploaded?).with(stemcell_name, stemcell_version).
          and_return(true)
      end

      it "writes a message and does not upload anything" do
        allow(bosh.logger).to receive(:log_and_puts)

        bosh.upload_stemcell(stemcell_config)

        expect(bosh.logger).to have_received(:log_and_puts).
          with(:info, "Stemcell #{stemcell_name}/#{stemcell_version} already uploaded.")
      end
    end

    context 'when the stemcell is not uploaded yet' do
      before do
        allow(bosh_client).
          to receive(:stemcell_uploaded?).with(stemcell_name, stemcell_version).
          and_return(false)
      end

      it "uploads a stemcell with the client" do
        allow(bosh_client).to receive(:upload_stemcell)

        bosh.upload_stemcell(stemcell_config)

        expect(bosh_client).
          to have_received(:upload_stemcell).with(stemcell_uri, stemcell_sha)
      end
    end
  end

  describe '#update_cloud_config' do
    let(:cloud_config) { { "azs" => [{ "name" => "z1" }] } }
    let(:file) { Tempfile.new }

    it "updates the cloud config with the given config with the client" do
      filepath = file.path # this must be done before the method run and the file is unlinked
      allow(Tempfile).to receive(:new).with("cloud-config.yml").and_return(file)
      allow(file).to receive(:write)
      allow(bosh_client).to receive(:update_cloud_config)

      bosh.update_cloud_config(cloud_config)

      expect(file).to have_received(:write).with(cloud_config.to_yaml)
      expect(bosh_client).to have_received(:update_cloud_config).with(filepath)
    end
  end

  describe '#deploy_git_server' do
    let(:manifest) { { "name" => "deployment" } }
    let(:file) { Tempfile.new }

    context "when the release is not already uploaded" do
      before do
        allow(bosh_client).to receive(:release_uploaded?).
          and_return(false)
      end

      it "uploads the release, writes the manifest and run the deploy command" do
        filepath = file.path # this must be done before the method run and the file is unlinked
        allow(bosh_client).to receive(:upload_release)
        allow(Tempfile).to receive(:new).with("git-server.yml").and_return(file)
        allow(file).to receive(:write)
        allow(bosh_client).to receive(:deploy)

        bosh.deploy_git_server(manifest)

        expect(bosh_client).to have_received(:upload_release).
          with("https://bosh.io/d/github.com/cloudfoundry-community/git-server-release?v=3", "682a70517c495455f43545b9ae39d3f11d24d94c")
        expect(file).to have_received(:write).with(manifest.to_yaml)
        expect(bosh_client).to have_received(:deploy).with("git-server", filepath)
      end
    end

    context "when the release is already uploaded" do
      before do
        allow(bosh_client).to receive(:release_uploaded?).
          and_return(true)
      end

      it "uploads the release, writes the manifest and run the deploy command" do
        filepath = file.path # this must be done before the method run and the file is unlinked
        allow(bosh.logger).to receive(:log_and_puts)
        allow(bosh_client).to receive(:upload_release)
        allow(Tempfile).to receive(:new).with("git-server.yml").and_return(file)
        allow(file).to receive(:write)
        allow(bosh_client).to receive(:deploy)

        bosh.deploy_git_server(manifest)

        expect(bosh.logger).to have_received(:log_and_puts).
          with(:info, "BOSH release git-server/3 already uploaded.")
        expect(bosh_client).not_to have_received(:upload_release)
        expect(file).to have_received(:write).with(manifest.to_yaml)
        expect(bosh_client).to have_received(:deploy).with("git-server", filepath)
      end
    end
  end
end
