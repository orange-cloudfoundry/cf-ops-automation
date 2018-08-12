require 'spec_helper'
require 'tempfile'
require 'coa_env_bootstrapper'
require 'coa_env_bootstrapper/runner'
require 'coa_env_bootstrapper/bosh'
require 'coa_env_bootstrapper/concourse'
require 'coa_env_bootstrapper/git'

describe CoaEnvBootstrapper::Runner do
  let(:tempfile) { Tempfile.new }

  describe '.new' do
    let(:bosh_prereqs_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'bosh-prereqs.yml') }
    let(:bucc_prereqs_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'bucc-prereqs.yml') }
    let(:not_existing_path) { "not_existing.yml" }
    let(:expected_prereqs) do
      {
        "bosh" => {
          "bosh_environment"   => "own_bosh",
          "bosh_target"        => "target",
          "bosh_client"        => "client",
          "bosh_client_secret" => "client_secret",
          "bosh_ca_cert"       => "ca_cert"
        },
        "bucc" => {
          "bin_path"             => "/path/to/bucc/bin",
          "cpi"                  => "openstack",
          "cpi_specific_options" => "--keystone-v2"
        }
      }
    end

    it "loads proper arguments files and ignore others" do
      runner = described_class.new([bosh_prereqs_path, bucc_prereqs_path, not_existing_path])

      expect(runner.prereqs).to eq(expected_prereqs)
    end
  end

  describe '#run' do
    let(:generated_concourse_credentials) { { "secret-uri" => "generated" } }
    let(:bosh) { CoaEnvBootstrapper::Bosh.new({}) }
    let(:git) { CoaEnvBootstrapper::Git.new(bosh, {}) }
    let(:concourse) { CoaEnvBootstrapper::Concourse.new({}) }
    let(:env_creator_adapter) { CoaEnvBootstrapper::EnvCreatorAdapter.new("bucc", {}) }
    let(:git_server_ip) { "1.1.1.1" }

    before do
      allow(runner).to receive(:bosh).and_return(bosh)
      allow(runner).to receive(:git).and_return(git)
      allow(runner).to receive(:concourse).and_return(concourse)
      allow(runner).to receive(:env_creator_adapter).and_return(env_creator_adapter)
      allow(Tempfile).to receive(:new).and_return(tempfile)
      allow(bosh).to receive(:git_server_ip).and_return(git_server_ip)
    end

    context "with no configuration" do
      let(:runner) { described_class.new([]) }

      it "runs all steps" do
        pipeline_vars_filepath = tempfile.path
        allow(env_creator_adapter).to receive(:deploy_transient_infra)
        allow(bosh).to receive(:upload_stemcell)
        allow(bosh).to receive(:update_cloud_config)
        allow(bosh).to receive(:deploy_git_server)
        allow(git).to receive(:push_templates_repo)
        allow(git).to receive(:push_secrets_repo)
        allow(git).to receive(:push_cf_ops_automation)
        allow(concourse).to receive(:set_pipelines)
        allow(concourse).to receive(:unpause_pipelines)
        allow(concourse).to receive(:trigger_jobs)

        runner.run

        expect(env_creator_adapter).to have_received(:deploy_transient_infra)
        expect(bosh).to have_received(:upload_stemcell)
        expect(bosh).to have_received(:update_cloud_config)
        expect(bosh).to have_received(:deploy_git_server)
        expect(git).to have_received(:push_templates_repo)
        expect(git).to have_received(:push_secrets_repo)
        expect(git).to have_received(:push_cf_ops_automation)
        expect(concourse).to have_received(:set_pipelines).
          with(pipeline_vars_filepath, git_server_ip)
        expect(concourse).to have_received(:unpause_pipelines)
        expect(concourse).to have_received(:trigger_jobs)
      end
    end

    context "when passed a configuration deactiving steps" do
      let(:inactive_steps_yml_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'inactive_steps.yml') }
      let(:runner) { described_class.new([inactive_steps_yml_path]) }

      it "ignores the deactivated steps" do
        pipeline_vars_filepath = tempfile.path
        allow(env_creator_adapter).to receive(:deploy_transient_infra)
        allow(bosh).to receive(:upload_stemcell)
        allow(bosh).to receive(:update_cloud_config)
        allow(bosh).to receive(:deploy_git_server)
        allow(git).to receive(:push_templates_repo)
        allow(git).to receive(:push_secrets_repo)
        allow(git).to receive(:push_cf_ops_automation)
        allow(concourse).to receive(:set_pipelines)
        allow(concourse).to receive(:unpause_pipelines)
        allow(concourse).to receive(:trigger_jobs)

        runner.run

        expect(bosh).to have_received(:update_cloud_config)
        expect(git).to have_received(:push_templates_repo)
        expect(git).to have_received(:push_secrets_repo)
        expect(git).to have_received(:push_cf_ops_automation)
        expect(concourse).to have_received(:set_pipelines).
          with(pipeline_vars_filepath, git_server_ip)
        expect(concourse).to have_received(:unpause_pipelines)
        expect(concourse).to have_received(:trigger_jobs)
      end
    end
  end

  describe '#run_pipeline_jobs' do
    context 'when the concourse creds are provided' do
      let(:pipeline_vars_prereqs_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'pipeline-vars-prereqs.yml') }
      let(:bosh_prereqs_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'bosh-prereqs.yml') }
      let(:concourse_prereqs_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'concourse-prereqs.yml') }
      let(:runner) do
        described_class.new([bosh_prereqs_path, pipeline_vars_prereqs_path, concourse_prereqs_path])
      end
      let(:bosh_config) { YAML.load_file(bosh_prereqs_path) }
      let(:concourse_config) { YAML.load_file(concourse_prereqs_path) }
      let(:bosh) { CoaEnvBootstrapper:: Bosh.new(bosh_config["bosh"]) }
      let(:concourse) { CoaEnvBootstrapper:: Concourse.new(concourse_config["concourse"]) }
      let(:git_server_ip) { "1.1.1.1" }
      let(:pipeline_vars) { YAML.load_file(pipeline_vars_prereqs_path)["pipeline-vars"] }
      let(:generated_vars) do
        {
          "bosh-target"      => "target",
          "bosh-username"    => "client",
          "bosh-password"    => "client_secret",
          "bosh-ca-cert"     => "ca_cert",
          "bosh-environment" => "target",
          "secrets-uri"           => "git://#{git_server_ip}/secrets",
          "paas-templates-uri"    => "git://#{git_server_ip}/paas-templates",
          "cf-ops-automation-uri" => "git://#{git_server_ip}/cf-ops-automation",
          "concourse-hello-world-root-depls-insecure" => "true",
          "concourse-hello-world-root-depls-password" => "concourse_password",
          "concourse-hello-world-root-depls-target"   => "http://example.com",
          "concourse-hello-world-root-depls-username" => "concourse_username"
        }
      end

      before do
        allow(runner).to receive(:bosh).and_return(bosh)
        allow(runner).to receive(:concourse).and_return(concourse)
        allow(bosh).to receive(:git_server_ip).and_return(git_server_ip)
        allow(Tempfile).to receive(:new).and_return(tempfile)
      end

      it "returns a hash using the provided creds" do
        pipeline_vars_filepath = tempfile.path # needed to create the value before it is nullified in the class via .unlink
        allow(tempfile).to receive(:write)
        allow(concourse).to receive(:set_pipelines)
        allow(concourse).to receive(:unpause_pipelines)
        allow(concourse).to receive(:trigger_jobs)

        runner.run_pipeline_jobs

        expect(tempfile).to have_received(:write).with(generated_vars.merge(pipeline_vars).to_yaml)
        expect(concourse).to have_received(:set_pipelines).with(pipeline_vars_filepath, git_server_ip)
        expect(concourse).to have_received(:unpause_pipelines)
        expect(concourse).to have_received(:trigger_jobs)
      end
    end

    context 'when the bosh creds and concourse creds come from bucc'
  end
end
