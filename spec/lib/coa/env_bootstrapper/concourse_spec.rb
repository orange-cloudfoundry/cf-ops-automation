require 'spec_helper'
require 'coa/env_bootstrapper/base'
require 'coa/env_bootstrapper/concourse'
require 'coa/utils/concourse/fly'
require 'coa/utils/bosh/config'

describe Coa::EnvBootstrapper::Concourse do
  let(:concourse_config) do
    Coa::Utils::Concourse::Config.new(
      "concourse_target" => "env",
      "concourse_url" => "192.0.0.1",
      "concourse_username" => "admin",
      "concourse_password" => "secr3t",
      "concourse_insecure" => "true",
      "concourse_ca_cert" => ""
    )
  end
  let(:concourse) { described_class.new(concourse_config) }
  let(:client) { concourse.client }

  describe '#set_pipelines' do
    let(:git_server_ip) { "5.6.7.8" }
    let(:prereqs_pipeline_vars) { {} }
    let(:pipeline_vars_path) { "/path/to/vars-file.yml" }
    let(:bosh_config) { Coa::Utils::Bosh::Config.new }
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
    let(:tempfile) { instance_double("Tempfile") }

    it "write down the concourse credentials and run the 'set-pipeline' command" do
      allow(Tempfile).to receive(:new).with("pipeline-vars.yml").
        and_return(tempfile)
      allow(tempfile).to receive(:write)
      allow(tempfile).to receive(:close)
      allow(tempfile).to receive(:path).and_return(pipeline_vars_path)
      allow(tempfile).to receive(:unlink)
      allow(client).to   receive(:set_pipeline)

      concourse.set_pipelines(prereqs_pipeline_vars, bosh_config, git_server_ip)

      expect(Tempfile).to have_received(:new).with("pipeline-vars.yml")
      expect(tempfile).to have_received(:write)
      expect(tempfile).to have_received(:close)
      expect(tempfile).to have_received(:path)
      expect(tempfile).to have_received(:unlink)
      expect(client).to   have_received(:set_pipeline).
        with(name: "bootstrap-all-init-pipelines", options: options)
    end
  end

  describe '#start_pipeline' do
    it "runs the `fly unpause-pipelines` command" do
      allow(client).to receive(:unpause_pipeline)

      concourse.start_pipeline

      expect(client).to have_received(:unpause_pipeline)
        .with(name: "bootstrap-all-init-pipelines")
    end
  end

  describe '#run_pipelines' do
    let(:pipeline_vars_prereqs_path) { File.join(fixtures_dir('lib'), 'coa', 'env_bootstrapper', 'pipeline-vars-prereqs.yml') }
    let(:pipeline_vars) { YAML.load_file(pipeline_vars_prereqs_path)["pipeline-vars"] }
    let(:bosh_config) { Coa::Utils::Bosh::Config.new }
    let(:bs) { described_class.new(concourse_config) }
    let(:git_server_ip) { "1.1.1.1" }

    it "returns a hash using the provided creds" do
      allow(bs).to receive(:set_pipelines)
      allow(bs.client).to receive(:unpause_pipeline)

      bs.run_pipelines(
        inactive_steps:        [],
        prereqs_pipeline_vars: pipeline_vars,
        bosh_config:           bosh_config,
        git_server_ip:         git_server_ip
      )

      expect(bs).to have_received(:set_pipelines).with(pipeline_vars, bosh_config, git_server_ip)
      expect(bs.client).to have_received(:unpause_pipeline).
        with(name: "bootstrap-all-init-pipelines")
    end
  end
end
