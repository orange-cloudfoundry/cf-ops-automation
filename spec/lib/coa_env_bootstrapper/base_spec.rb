require 'spec_helper'
require 'coa_env_bootstrapper'
require 'coa_env_bootstrapper/base'

describe CoaEnvBootstrapper::Base do
  describe '.new' do
    let(:prereqs_yml_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'prereqs.yml') }
    let(:private_prereqs_yml_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'private_prereqs.yml') }
    let(:not_existing_yml_path) { "not_existing.yml" }
    let(:expected_prereqs) do
      {
        "pipeline-crendentials" => {
          "slack-webhook" => "https://example.slack.com/webhook"
        },
        "bosh_client_secret" => "secret"
      }
    end

    it "loads proper arguments files and ignore others" do
      allow(described_class).to receive(:puts).with("File #{not_existing_yml_path} not found. Will be ignored.")

      ceb = described_class.new([prereqs_yml_path, private_prereqs_yml_path, not_existing_yml_path])

      expect(ceb.prereqs).to eq(expected_prereqs)
    end
  end

  describe '#run' do
    let(:generated_concourse_credentials) { { "secret-uri" => "generated" } }

    context "with a default configuration" do
      let(:ceb) { described_class.new([]) }

      it "runs all steps" do
        allow(ceb.env_creator_adapter).to receive(:deploy_transient_infra)
        allow(ceb).to receive(:write_source_profile)
        allow(ceb.bosh).to receive(:upload_stemcell)
        allow(ceb.bosh).to receive(:upload_cloud_config)
        allow(ceb.bosh).to receive(:deploy_git_server)
        allow(ceb.git).to receive(:push_templates_repo)
        allow(ceb.git).to receive(:push_secrets_repo)
        allow(ceb.git).to receive(:download_git_dependencies)
        allow(ceb).to receive(:generated_concourse_credentials).
          and_return(generated_concourse_credentials)
        allow(ceb.concourse).to receive(:upload_pipelines)
        allow(ceb.concourse).to receive(:unpause_pipelines)
        allow(ceb.concourse).to receive(:trigger_jobs)
        allow(ceb.env_creator_adapter).to receive(:display_concourse_login_information)

        ceb.run

        expect(ceb.env_creator_adapter).to have_received(:deploy_transient_infra)
        expect(ceb).to have_received(:write_source_profile)
        expect(ceb.bosh).to have_received(:upload_stemcell)
        expect(ceb.bosh).to have_received(:upload_cloud_config)
        expect(ceb.bosh).to have_received(:deploy_git_server)
        expect(ceb.git).to have_received(:push_templates_repo)
        expect(ceb.git).to have_received(:push_secrets_repo)
        expect(ceb.git).to have_received(:download_git_dependencies)
        expect(ceb.concourse).to have_received(:upload_pipelines).
          with(ceb.config_dir, generated_concourse_credentials)
        expect(ceb.concourse).to have_received(:unpause_pipelines)
        expect(ceb.concourse).to have_received(:trigger_jobs)
        expect(ceb.env_creator_adapter).to have_received(:display_concourse_login_information)
      end
    end

    context "when passed a configuration deactiving steps" do
      let(:inactive_steps_yml_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'inactive_steps.yml') }
      let(:ceb) { described_class.new([inactive_steps_yml_path]) }

      it "ignores the deactivated steps" do
        allow(ceb.env_creator_adapter).to receive(:deploy_transient_infra)
        allow(ceb).to receive(:write_source_profile)
        allow(ceb.bosh).to receive(:upload_stemcell)
        allow(ceb.bosh).to receive(:upload_cloud_config)
        allow(ceb.bosh).to receive(:deploy_git_server)
        allow(ceb.git).to receive(:push_templates_repo)
        allow(ceb.git).to receive(:push_secrets_repo)
        allow(ceb.git).to receive(:download_git_dependencies)
        allow(ceb).to receive(:generated_concourse_credentials).
          and_return(generated_concourse_credentials)
        allow(ceb.concourse).to receive(:upload_pipelines)
        allow(ceb.concourse).to receive(:unpause_pipelines)
        allow(ceb.concourse).to receive(:trigger_jobs)
        allow(ceb.env_creator_adapter).to receive(:display_concourse_login_information)

        ceb.run

        expect(ceb.env_creator_adapter).not_to have_received(:deploy_transient_infra)
        expect(ceb).to have_received(:write_source_profile)
        expect(ceb.bosh).not_to have_received(:upload_stemcell)
        expect(ceb.bosh).to have_received(:upload_cloud_config)
        expect(ceb.bosh).not_to have_received(:deploy_git_server)
        expect(ceb.git).to have_received(:push_templates_repo)
        expect(ceb.git).to have_received(:push_secrets_repo)
        expect(ceb.git).to have_received(:download_git_dependencies)
        expect(ceb.concourse).to have_received(:upload_pipelines).
          with(ceb.config_dir, generated_concourse_credentials)
        expect(ceb.concourse).to have_received(:unpause_pipelines)
        expect(ceb.concourse).to have_received(:trigger_jobs)
        expect(ceb.env_creator_adapter).not_to have_received(:display_concourse_login_information)
      end
    end
  end

  describe '#generated_concourse_credentials' do
    context 'when the bosh creds and the concourse creds are provided' do
      let(:bosh_yml_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'bosh_prereqs.yml') }
      let(:concourse_yml_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'concourse_prereqs.yml') }
      let(:ceb) { described_class.new([bosh_yml_path, concourse_yml_path]) }
      let(:git_server_ip) { "1.1.1.1" }
      let(:expected_answer) do
        {
          "bosh-target"      => "target",
          "bosh-username"    => "client",
          "bosh-password"    => "client_secret",
          "bosh-ca-cert"     => "ca_cert",
          "bosh-environment" => "target",
          "secrets-uri"        => "git://#{git_server_ip}/secrets",
          "paas-templates-uri" => "git://#{git_server_ip}/paas-templates",
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

  describe '#write_source_profile' do
    let(:tmpdirpath) { Dir.mktmpdir }

    after { FileUtils.remove_entry_secure tmpdirpath }

    context 'when we pass a set of bosh credentials' do
      let(:bosh_yml_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'bosh_prereqs.yml') }
      let(:ceb) { described_class.new([bosh_yml_path]) }
      let(:source_profile_path) { File.join(tmpdirpath, CoaEnvBootstrapper::SOURCE_FILE_NAME) }
      let(:expected_profile) do
        [
          "export BOSH_ENVIRONMENT='own_bosh'",
          "export BOSH_TARGET='target'",
          "export BOSH_CLIENT='client'",
          "export BOSH_CLIENT_SECRET='client_secret'",
          "export BOSH_CA_CERT='ca_cert'"
        ].join("\n")
      end

      it "writes them in a file" do
        allow(File).to receive(:write)
        allow(ceb).to receive(:source_profile_path).and_return(source_profile_path)

        ceb.write_source_profile

        expect(File).to have_received(:write).with(source_profile_path, expected_profile)
      end
    end

    context 'when we do not pass our own credentials' do
      let(:ceb) { described_class.new([]) }
      let(:source_profile_path) { File.join(tmpdirpath, CoaEnvBootstrapper::SOURCE_FILE_NAME) }
      let(:bucc_vars) do
        {
          "bosh_environment" => 'bucc',
          "bosh_target" => 'bucc',
          "bosh_client" => 'client',
          "bosh_client_secret" => 'client_secret',
          "bosh_ca_cert" => 'ca_cert'
        }
      end
      let(:expected_profile) do
        [
          "export BOSH_ENVIRONMENT='bucc'",
          "export BOSH_TARGET='bucc'",
          "export BOSH_CLIENT='client'",
          "export BOSH_CLIENT_SECRET='client_secret'",
          "export BOSH_CA_CERT='ca_cert'"
        ].join("\n")
      end

      it "get the bosh credentials from bucc" do
        allow(ceb.env_creator_adapter).to receive(:vars).and_return(bucc_vars)
        allow(File).to receive(:write)
        allow(ceb).to receive(:source_profile_path).and_return(source_profile_path)

        ceb.write_source_profile

        expect(File).to have_received(:write).with(source_profile_path, expected_profile)
      end
    end
  end

  describe '.create_file_from_prereqs'
end
