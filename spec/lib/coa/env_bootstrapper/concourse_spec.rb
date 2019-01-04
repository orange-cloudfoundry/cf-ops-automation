require 'spec_helper'
require 'coa/env_bootstrapper/base'
require 'coa/env_bootstrapper/concourse'
require 'coa/utils/concourse/fly'

describe Coa::EnvBootstrapper::Concourse do
  let(:config_source) do
    {
      "concourse_target" => "env",
      "concourse_url" => "192.0.0.1",
      "concourse_username" => "admin",
      "concourse_password" => "secr3t",
      "concourse_insecure" => "true",
      "concourse_ca_cert" => ""
    }
  end
  let(:concourse_config) do
    {
      "target"   => "env",
      "url"      => "192.0.0.1",
      "username" => "admin",
      "password" => "secr3t",
      "insecure" => "true",
      "ca_cert"  => ""
    }
  end
  let(:concourse) { described_class.new(config_source) }
  let(:client) { concourse.client }

  before do
    allow(Coa::Utils::Concourse::Fly).to receive(:login)
  end

  describe '#set_pipelines' do
    let(:git_server_ip) { "5.6.7.8" }
    let(:pipeline_vars_path) { "/path/to/vars-file.yml" }

    let(:options) do
      "--config #{described_class::PROJECT_ROOT_DIR}/concourse/pipelines/bootstrap-all-init-pipelines.yml \
--load-vars-from #{pipeline_vars_path} \
--var paas-templates-uri='git://#{git_server_ip}/paas-templates' \
--var secrets-uri='git://#{git_server_ip}/secrets' \
--var cf-ops-automation-uri='git://#{git_server_ip}/cf-ops-automation' \
--var concourse-micro-depls-target='192.0.0.1' \
--var concourse-micro-depls-username='admin' \
--var concourse-micro-depls-password='secr3t'"
    end

    it "write down the concourse credentials and run the 'set-pipeline' command" do
      allow(client).to receive(:set_pipeline)

      concourse.set_pipelines(pipeline_vars_path, git_server_ip)

      expect(client).to have_received(:set_pipeline).
        with("bootstrap-all-init-pipelines", options)
    end
  end

  describe '#unpause_pipelines' do
    it "runs the `fly unpause-pipelines` command" do
      allow(client).to receive(:unpause_pipeline)

      concourse.unpause_pipelines

      expect(client).to have_received(:unpause_pipeline)
        .with("bootstrap-all-init-pipelines")
    end
  end

  describe '#trigger_jobs' do
    it "runs the `fly trigger-jobs` command" do
      allow(client).to receive(:trigger_job)

      concourse.trigger_jobs

      expect(client).to have_received(:trigger_job).
        with("bootstrap-all-init-pipelines/bootstrap-init-pipelines")
    end
  end
end
