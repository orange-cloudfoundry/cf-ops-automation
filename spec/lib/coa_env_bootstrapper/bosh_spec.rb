require 'spec_helper'
require 'coa_env_bootstrapper/base'
require 'coa_env_bootstrapper/bosh'

describe CoaEnvBootstrapper::Bosh do
  describe '.new'

  describe '#upload_stemcell' do
    let(:stemcell_name) { "bosh-warden-boshlite-ubuntu-trusty-go_agent" }
    let(:stemcell_version) { "3586.23" }
    let(:stemcell_uri) { "example.com" }
    let(:stemcell_sha) { "1234abcd" }
    let(:prereqs) do
      {
        "stemcell" => {
          "name" => stemcell_name,
          "version" => stemcell_version,
          "uri" => stemcell_uri,
          "sha" => stemcell_sha
        }
      }
    end
    let(:ceb) do
      instance_double(CoaEnvBootstrapper::Base, prereqs: prereqs, source_profile_path: "")
    end
    let(:bosh) { described_class.new(ceb) }

    context 'when the stemcell is already uploaded' do
      let(:bosh_stemcells_answer) do
        "#{stemcell_name}	#{stemcell_version}*\nbosh-warden-boshlite-ubuntu-xenial-go_agent	3586.24"
      end

      it "writes a message and does not upload anything" do
        allow(bosh).to receive(:run_cmd).
          with("bosh stemcells --column name --column version | cut -f1,2", source_file_path: ceb.source_profile_path).
          and_return(bosh_stemcells_answer)
        allow(bosh).to receive(:puts)

        bosh.upload_stemcell

        expect(bosh).to have_received(:puts).with("Stemcell #{stemcell_name}/#{stemcell_version} already uploaded.")
      end
    end

    context 'when the stemcell is not uploaded yet' do
      let(:bosh_stemcells_answer) { "" }

      it "writes a message and does not upload anything" do
        allow(bosh).to receive(:run_cmd).
          with("bosh stemcells --column name --column version | cut -f1,2", source_file_path: ceb.source_profile_path).
          and_return(bosh_stemcells_answer)
        allow(bosh).to receive(:run_cmd).
          with("bosh -n upload-stemcell --sha1 #{stemcell_sha} #{stemcell_uri}", source_file_path: ceb.source_profile_path)

        bosh.upload_stemcell

        expect(bosh).to have_received(:run_cmd).
          with("bosh -n upload-stemcell --sha1 #{stemcell_sha} #{stemcell_uri}", source_file_path: ceb.source_profile_path)
      end
    end
  end

  pending '#upload_cloud_config' do
    let(:cloud_config_fixtures_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'cloud_config.yml') }
    let(:ceb) { CoaEnvBootstrapper::Base.new([cloud_config_fixtures_path]) }
    let(:bosh) { described_class.new(ceb) }
    let(:tmpdirpath) { Dir.mktmpdir("upload_cloud_config") }
    let(:cloud_config_yaml) { File.join(tmpdirpath, 'cloud-config.yml') }

    after { FileUtils.remove_entry_secure tmpdirpath }

    it "creates a cloud-config from the prereqs and uploads it" do
      allow(bosh).to receive(:run_cmd)
      cloud_config = File.read(cloud_config_fixtures_path)
      allow(File).to receive(:write).with(cloud_config)

      bosh.upload_cloud_config(tmpdirpath)

      expect(bosh).to have_received(:run_cmd).
        with("bosh -n update-cloud-config #{cloud_config_yaml}", source_file_path: ceb.source_profile_path)
    end
  end

  describe '#deploy_git_server' do
    let(:git_server_manifest_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'git_server_manifest.yml') }
    let(:ceb) { CoaEnvBootstrapper::Base.new([git_server_manifest_path]) }
    let(:bosh) { described_class.new(ceb) }
    let(:tmpdirpath) { Dir.mktmpdir }
    let(:manifest_path) { File.join(tmpdirpath, 'git-server.yml') }

    after { FileUtils.remove_entry_secure tmpdirpath }

    context "when the release is not already uploaded" do
      let(:command_answer) { "" }

      it "uploads the release, writes the manifest and run the deploy command" do
        manifest = YAML.dump(YAML.safe_load(File.read(git_server_manifest_path))["git_server_manifest"])

        allow(ceb).to receive(:source_profile_path).and_return("")
        allow(bosh).to receive(:run_cmd).
          with("bosh releases --column name --column version | cut -f1,2", source_file_path: ceb.source_profile_path).
          and_return(command_answer)
        allow(bosh).to receive(:run_cmd).
          with("bosh upload-release --sha1 682a70517c495455f43545b9ae39d3f11d24d94c \
https://bosh.io/d/github.com/cloudfoundry-community/git-server-release?v=3", source_file_path: ceb.source_profile_path)
        allow(bosh).to receive(:run_cmd).
          with("bosh -n deploy -d git-server #{manifest_path} -v repos=[paas-templates,secrets]", source_file_path: ceb.source_profile_path)

        bosh.deploy_git_server(tmpdirpath)

        expect(File.read(manifest_path)).to eq(manifest)
        expect(bosh).to have_received(:run_cmd).
          with("bosh upload-release --sha1 682a70517c495455f43545b9ae39d3f11d24d94c \
https://bosh.io/d/github.com/cloudfoundry-community/git-server-release?v=3", source_file_path: ceb.source_profile_path)
        expect(bosh).to have_received(:run_cmd).
          with("bosh -n deploy -d git-server #{manifest_path} -v repos=[paas-templates,secrets]", source_file_path: ceb.source_profile_path)
      end
    end

    context "when the release is already uploaded" do
      let(:command_answer) { "git-server  3*" }

      it "does not run the bosh `upload-release` command" do
        manifest = YAML.dump(YAML.safe_load(File.read(git_server_manifest_path))["git_server_manifest"])

        allow(ceb).to receive(:source_profile_path).and_return("")
        allow(bosh).to receive(:run_cmd).
          with("bosh releases --column name --column version | cut -f1,2", source_file_path: ceb.source_profile_path).
          and_return(command_answer)
        allow(bosh).to receive(:run_cmd).
          with("bosh upload-release --sha1 682a70517c495455f43545b9ae39d3f11d24d94c \
https://bosh.io/d/github.com/cloudfoundry-community/git-server-release?v=3", source_file_path: ceb.source_profile_path)
        allow(bosh).to receive(:run_cmd).
          with("bosh -n deploy -d git-server #{manifest_path} -v repos=[paas-templates,secrets]", source_file_path: ceb.source_profile_path)

        bosh.deploy_git_server(tmpdirpath)

        expect(File.read(manifest_path)).to eq(manifest)
        expect(bosh).not_to have_received(:run_cmd).
          with("bosh upload-release --sha1 682a70517c495455f43545b9ae39d3f11d24d94c \
https://bosh.io/d/github.com/cloudfoundry-community/git-server-release?v=3", source_file_path: ceb.source_profile_path)
        expect(bosh).to have_received(:run_cmd).
          with("bosh -n deploy -d git-server #{manifest_path} -v repos=[paas-templates,secrets]", source_file_path: ceb.source_profile_path)
      end
    end
  end

  describe "#creds"
end
