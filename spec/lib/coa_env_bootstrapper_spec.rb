require 'spec_helper'
require_relative '../../lib/coa_env_bootstrapper'

describe CoaEnvBootstrapper do
  describe '#new' do
    it "creates a temporary directory" do
      ceb = CoaEnvBootstrapper.new([])
      expect(File.exist?(ceb.tmpdir)).to be_truthy
      expect(File.directory?(ceb.tmpdir)).to be_truthy
    end

    it "loads proper arguments files and ignore others" do
      prereqs_yml_path = File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'prereqs.yml')
      private_prereqs_yml_path = File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'private_prereqs.yml')
      not_existing_yml_path = "not_existing.yml"

      expect_any_instance_of(CoaEnvBootstrapper).
        to receive(:puts).with("File #{not_existing_yml_path} not found. Will be ignored.")
      ceb = CoaEnvBootstrapper.
        new([prereqs_yml_path, private_prereqs_yml_path, not_existing_yml_path])
      expect(ceb.prereqs).
        to eq({ "bosh_environment" => "bucc", "bosh_client_secret" => "secret"})
    end
  end

  describe '#execute' do
    it "runs all steps with a default config" do
      ceb = CoaEnvBootstrapper.new([])

      expect(ceb).to receive(:deploy_transiant_infra)
      expect(ceb).to receive(:write_env_file)
      expect(ceb).to receive(:upload_stemcell)
      expect(ceb).to receive(:upload_cloud_config)
      expect(ceb).to receive(:install_git_server)
      expect(ceb).to receive(:push_templates_repo)
      expect(ceb).to receive(:push_secrets_repo)
      expect(ceb).to receive(:download_git_dependencies)
      expect(ceb).to receive(:upload_pipelines)
      expect(ceb).to receive(:unpause_pipelines)
      expect(ceb).to receive(:trigger_jobs)

      ceb.execute
    end

    it "ignores some steps when receiving the appropriate config" do
      inactive_steps_yml_path = File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'inactive_steps.yml')
      ceb = CoaEnvBootstrapper.new([inactive_steps_yml_path])

      expect(ceb).not_to receive(:deploy_transiant_infra)
      expect(ceb).to receive(:write_env_file)
      expect(ceb).not_to receive(:upload_stemcell)
      expect(ceb).to receive(:upload_cloud_config)
      expect(ceb).not_to receive(:install_git_server)
      expect(ceb).to receive(:push_templates_repo)
      expect(ceb).to receive(:push_secrets_repo)
      expect(ceb).to receive(:download_git_dependencies)
      expect(ceb).to receive(:upload_pipelines)
      expect(ceb).to receive(:unpause_pipelines)
      expect(ceb).to receive(:trigger_jobs)

      ceb.execute
    end
  end

  describe '#deploy_transiant_infra' do
    context "when the deployment is successful" do
      let(:exitstatus) { double(Process::Status, :success? => true) }

      it "runs the bucc up commands with the provided options without issue" do
        bucc_yml_path = File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'bucc.yml')
        ceb = CoaEnvBootstrapper.new([bucc_yml_path])

        expect(Open3).to receive(:capture3).
          with("bucc up --cpi openstack --keystone-v2 --lite --debug").
          and_return(["out", "err", exitstatus])

        ceb.deploy_transiant_infra
      end
    end

    context "when the deployment is not successful" do
      let(:exitstatus) { double(Process::Status, :success? => false) }


      it "runs the bucc up commands with the provided options but fails" do
        bucc_yml_path = File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'bucc.yml')
        ceb = CoaEnvBootstrapper.new([bucc_yml_path])

        expect(Open3).to receive(:capture3).
          with("bucc up --cpi openstack --keystone-v2 --lite --debug").
          and_return(["out", "err", exitstatus])

        expect { ceb.deploy_transiant_infra }.
          to raise_error("Command errored with outputs:\nstderr:\nerr\nstdout:\nout")
      end
    end
  end

  describe '#write_env_file' do
    context 'when we pass a set of bosh credentials' do
      it "writes them in a file"
    end

    context 'when we get the bosh credentials from bucc' do
      it "writes them in a file"
    end
  end
end
