require 'spec_helper'
require 'coa_env_bootstrapper'
require 'coa_env_bootstrapper/base'

describe CoaEnvBootstrapper::Base do
  describe '.new' do
    let(:prereqs_yml_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'prereqs.yml') }
    let(:private_prereqs_yml_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'private_prereqs.yml') }
    let(:not_existing_yml_path) { "not_existing.yml" }

    it "creates a temporary directory" do
      ceb = CoaEnvBootstrapper::Base.new([])
      expect(File.exist?(ceb.tmpdir)).to be_truthy
      expect(File.directory?(ceb.tmpdir)).to be_truthy
    end

    it "loads proper arguments files and ignore others" do
      expect_any_instance_of(CoaEnvBootstrapper::Base).
        to receive(:puts).with("File #{not_existing_yml_path} not found. Will be ignored.")
      ceb = CoaEnvBootstrapper::Base.
        new([prereqs_yml_path, private_prereqs_yml_path, not_existing_yml_path])
      expect(ceb.prereqs).
        to eq({ "bosh_environment" => "bucc", "bosh_client_secret" => "secret"})
    end
  end

  describe '#run' do
    context "with a default configuration" do
      let(:ceb) { CoaEnvBootstrapper::Base.new([]) }

      it "runs all steps" do
        expect(ceb.env_creator_adapter).to receive(:deploy_transiant_infra)
        expect(ceb).to receive(:write_source_file)
        expect(ceb.bosh).to receive(:prepare_environment).once
        expect(ceb.git).to receive(:prepare_environment).once
        expect(ceb.concourse).to receive(:run_pipeline_jobs).once

        expect(ceb.run).to eq ceb
      end
    end

    context "when passed a configuration deactiving steps" do
      let(:inactive_steps_yml_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'inactive_steps.yml') }
      let(:ceb) { CoaEnvBootstrapper::Base.new([inactive_steps_yml_path]) }

      it "ignores the deactivted steps" do
        expect(ceb.env_creator_adapter).not_to receive(:deploy_transiant_infra)
        expect(ceb).to receive(:write_source_file)
        expect(ceb.bosh).to receive(:prepare_environment).once
        expect(ceb.git).to receive(:prepare_environment).once
        expect(ceb.concourse).to receive(:run_pipeline_jobs).once

        expect(ceb.run).to eq ceb
      end
    end
  end

  describe '#clean' do
    let(:ceb) { CoaEnvBootstrapper::Base.new([]) }

    it "deletes the tmp file it created" do
      expect(File.exist?(ceb.tmpdir)).to be_truthy
      ceb.clean
      expect(File.exist?(ceb.tmpdir)).to be_falsy
    end
  end

  describe '#generated_concourse_credentials' do
    context 'when the bosh creds and the concourse creds are provided' do
      let(:bosh_yml_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'bosh_prereqs.yml') }
      let(:concourse_yml_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'concourse_prereqs.yml') }
      let(:ceb) { CoaEnvBootstrapper::Base.new([bosh_yml_path, concourse_yml_path]) }
      let(:git_server_ip) { "1.1.1.1" }
      let(:expected_answer) do
        {
          "bosh-target"   => "target",
          "bosh-username" => "client",
          "bosh-password" => "client_secret",
          "bosh-ca-cert"  => "ca_cert",
          "secrets-uri"        => "git://#{git_server_ip}/secrets",
          "paas-templates-uri" => "git://#{git_server_ip}/paas-templates",
          "concourse-micro-depls-target"   => "http://example.com",
          "concourse-micro-depls-username" => "concourse_username",
          "concourse-micro-depls-password" => "concourse_password",
          "concourse-hello-world-root-depls-insecure" => "true",
          "concourse-hello-world-root-depls-password" => "concourse_password",
          "concourse-hello-world-root-depls-target"   => "http://example.com",
          "concourse-hello-world-root-depls-username" => "concourse_username"
        }
      end

      it "returns a hash using the provided creds" do
        allow(ceb.git).to receive(:server_ip).
          and_return(git_server_ip)

        expect(ceb.generated_concourse_credentials).to eq(expected_answer)
      end
    end

    context 'when the bosh creds and concourse creds come from bucc'
  end

  pending '#deploy_transiant_infra' do
    let(:bucc_yml_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'bucc.yml') }
    let(:ceb) { CoaEnvBootstrapper::Base.new([bucc_yml_path]) }

    context "when the deployment is successful" do
      let(:exitstatus) { double(Process::Status, :success? => true) }

      it "runs the bucc up commands with the provided options without issue" do
        expect(Open3).to receive(:capture3).
          with("bucc up --cpi openstack --keystone-v2 --lite --debug").
          and_return(["out", "err", exitstatus])

        ceb.deploy_transiant_infra
      end
    end

    context "when the deployment is not successful" do
      let(:exitstatus) { double(Process::Status, :success? => false) }

      it "runs the bucc up commands with the provided options but fails" do
        expect(Open3).to receive(:capture3).
          with("bucc up --cpi openstack --keystone-v2 --lite --debug").
          and_return(["out", "err", exitstatus])

        expect { ceb.deploy_transiant_infra }.
          to raise_error("Command errored with outputs:\nstderr:\nerr\nstdout:\nout")
      end
    end
  end

  describe '#write_source_file' do
    context 'when we pass a set of bosh credentials' do
      let(:bosh_yml_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'bosh_prereqs.yml') }
      let(:ceb) { CoaEnvBootstrapper::Base.new([bosh_yml_path]) }
      let(:source_file_path) { File.join(ceb.tmpdir, CoaEnvBootstrapper::SOURCE_FILE_NAME) }
      let(:expected_profile) {
        [
          "export BOSH_ENVIRONMENT='own_bosh'",
          "export BOSH_TARGET='target'",
          "export BOSH_CLIENT='client'",
          "export BOSH_CLIENT_SECRET='client_secret'",
          "export BOSH_CA_CERT='ca_cert'"
        ].join("\n")
      }

      it "writes them in a file" do
        expect(File).to receive(:write).with(source_file_path, expected_profile)
        ceb.write_source_file
      end
    end

    context 'when we do not pass our own credentials' do
      let(:ceb) { CoaEnvBootstrapper::Base.new([]) }
      let(:source_file_path) { File.join(ceb.tmpdir, CoaEnvBootstrapper::SOURCE_FILE_NAME) }
      let(:bucc_vars) do
        {
          "bosh_environment" => 'bucc',
          "bosh_target" => 'target',
          "bosh_client" => 'client',
          "bosh_client_secret" => 'client_secret',
          "bosh_ca_cert" => 'ca_cert'
        }
      end
      let(:expected_profile) do
        [
          "export BOSH_ENVIRONMENT='bucc'",
          "export BOSH_TARGET='target'",
          "export BOSH_CLIENT='client'",
          "export BOSH_CLIENT_SECRET='client_secret'",
          "export BOSH_CA_CERT='ca_cert'"
        ].join("\n")
      end

      it "get the bosh credentials from bucc" do
        allow(ceb.env_creator_adapter).to receive(:vars).and_return(bucc_vars)
        expect(File).to receive(:write).with(source_file_path, expected_profile)
        ceb.write_source_file
      end
    end
  end
end
