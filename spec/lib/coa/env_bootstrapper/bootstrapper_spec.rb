require 'spec_helper'
require 'tempfile'
require 'coa/env_bootstrapper/bootstrapper'
require 'coa/env_bootstrapper/bosh'
require 'coa/env_bootstrapper/concourse'
require 'coa/env_bootstrapper/git'
require 'coa/env_bootstrapper/prereqs'

describe Coa::EnvBootstrapper::Bootstrapper do
  let(:tempfile) { Tempfile.new }
  let(:empty_prereqs) { Coa::EnvBootstrapper::Prereqs.new  }

  describe '.new' do
    let(:bosh_prereqs_path) { File.join(fixtures_dir('lib'), 'coa/env_bootstrapper', 'bosh-prereqs.yml') }
    let(:bucc_prereqs_path) { File.join(fixtures_dir('lib'), 'coa/env_bootstrapper', 'bucc-prereqs.yml') }
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

    xit "loads proper arguments files and ignore others" do
      bs = described_class.new([bosh_prereqs_path, bucc_prereqs_path, not_existing_path])

      expect(bs.prereqs).to eq(expected_prereqs)
    end
  end

  describe '#perform' do
    let(:generated_concourse_credentials) { { "secret-uri" => "generated" } }
    let(:bosh) { Coa::EnvBootstrapper::Bosh.new({}) }
    let(:git) { Coa::EnvBootstrapper::Git.new(bosh) }
    let(:concourse) { Coa::EnvBootstrapper::Concourse.new({}) }
    let(:env_creator) { Coa::EnvBootstrapper::EnvCreator.new() }
    let(:git_server_ip) { "1.1.1.1" }

    before do
      allow(bs).to       receive(:bosh).and_return(bosh)
      allow(bs).to       receive(:git).and_return(git)
      allow(bs).to       receive(:concourse).and_return(concourse)
      allow(bs).to       receive(:env_creator).and_return(env_creator)
      allow(Tempfile).to receive(:new).and_return(tempfile)
      allow(bosh).to     receive(:git_server_ip).and_return(git_server_ip)
    end

    context "with no configuration" do
      let(:bs) { described_class.new }

      it "executes all steps" do
        allow(env_creator).to receive(:deploy_transient_infra)
        allow(bosh).to        receive(:prepare_environment)
        allow(git).to         receive(:prepare_environment)
        allow(concourse).to   receive(:run_pipelines)

        bs.perform

        expect(env_creator).to have_received(:deploy_transient_infra)
        expect(bosh).to        have_received(:prepare_environment)
        expect(git).to         have_received(:prepare_environment)
        expect(concourse).to   have_received(:run_pipelines).
          with(
            inactive_steps:         empty_prereqs.inactive_steps,
            prereqs_pipeline_vars:  empty_prereqs.pipeline_vars,
            bosh_config:            bosh.config,
            git_server_ip:          bosh.git_server_ip
        )
      end
    end

    context "when passed a configuration deactiving steps" do
      let(:inactive_steps_yml_path) { File.join(fixtures_dir('lib'), 'coa', 'env_bootstrapper', 'inactive-steps-prereqs.yml') }
      let(:prereqs) { Coa::EnvBootstrapper::Prereqs.new_from_paths([inactive_steps_yml_path]) }
      let(:bs) { described_class.new(prereqs) }

      it "ignores the deactivated steps" do
        allow(env_creator).to receive(:deploy_transient_infra)
        allow(bosh).to        receive(:prepare_environment)
        allow(git).to         receive(:prepare_environment)
        allow(concourse).to   receive(:run_pipelines)

        bs.perform

        expect(env_creator).not_to have_received(:deploy_transient_infra)
        expect(bosh).to            have_received(:prepare_environment)
        expect(git).to             have_received(:prepare_environment)
        expect(concourse).to       have_received(:run_pipelines)
      end
    end
  end
end
