require 'spec_helper'
require 'coa_env_bootstrapper/base'
require 'coa_env_bootstrapper/git'

describe CoaEnvBootstrapper::Git do
  let(:ceb) { CoaEnvBootstrapper::Base.new([]) }
  let(:server_ip) { "1.2.3.4" }

  describe '.new'

  describe '#push_templates_repo' do
    it "runs a set of git commands"
  end

  describe '#push_secrets_repo' do
    it "runs a set of git commands"
  end

  describe '#download_git_dependencies' do
    let(:git) { described_class.new(ceb) }

    context "when ceb.config_dir is nil" do
      it "errors" do
        expect { git.download_git_dependencies }.
          to raise_error(CoaEnvBootstrapper::ConfigDirNotFound)
      end
    end

    context "when there is a config dir" do
      let(:tmpdir_path) { new_tmpdir_path }

      before { FileUtils.mkdir tmpdir_path }

      after { FileUtils.rm_r tmpdir_path }

      it "runs a set of git commands"
    end
  end

  describe '#server_ip' do
    let(:git) { described_class.new(ceb) }

    it "runs a set of git commands" do
      allow(ceb).to receive(:source_profile_path).and_return("")
      allow(git).to receive(:run_cmd).
        with("bosh -d git-server is --column ips|cut -f1", source_file_path: ceb.source_profile_path).
        and_return(server_ip)

      expect(git.server_ip).to eq server_ip
    end
  end
end
