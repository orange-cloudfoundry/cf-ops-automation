require 'spec_helper'
require 'tempfile'
require 'tasks'
require_relative '../../../concourse/tasks/bosh_delete_plan/delete_plan'

describe DeletePlan do
  let(:process_status_zero) { double(Process::Status, exitstatus: 0) }
  let(:process_status_one) { double(Process::Status, exitstatus: 1) }
  let(:error_filepath) { Tempfile.new }

  describe ".process" do
    context "when the environment is not complete" do
      before { allow(ENV).to receive(:[]).and_return("") }
      after {}

      it "error" do
        err_msg = "missing environment variable: ROOT_DEPLOYMENT_NAME"
        expect { DeletePlan.new.process }.
            to raise_error(Tasks::Bosh::EnvVarMissing, err_msg)
      end
    end

    context "when the environment is complete" do
      let(:delete_plan) { described_class.new(bosh_list_deployments, config_repo_deployments) }
      let(:cmd_env) { { "BOSH_ENVIRONMENT" => "1.2.3.4" } }
      let(:root_depl_name) { 'my-root-depls' }
      let(:protected) { %w[p1 p2 p3] }
      let(:protected_paths) { protected.map { |name| File.join('xx', root_depl_name, name, 'protect-deployment.yml') } }
      let(:expected) { %w[a b c p1] }
      let(:expected_paths) { expected.map { |name| File.join('xx', root_depl_name, name, 'enable-deployment.yml') } }
      let(:deployed) { %w[d1 d2 d3] + expected }
      let(:bosh_list_deployments) { instance_double(Tasks::Bosh::ListDeployments) }
      let(:config_repo_deployments) { instance_double(Tasks::ConfigRepo::Deployments) }

      before do
        allow(config_repo_deployments).to receive(:enabled_deployments).and_return(expected)
        allow(config_repo_deployments).to receive(:protected_deployments).and_return(protected)
        allow(config_repo_deployments).to receive(:cleanup_disabled_deployments)
        allow(bosh_list_deployments).to receive(:execute).and_return(deployed)
        allow(ENV).to receive(:fetch).with('OUTPUT_FILE', anything).and_return(error_filepath)
      end

      context "when all CLI commands run successfully" do
        it "run the bosh cancel-task command on processing tasks" do
          expect { delete_plan.process }.to output(/d1.* deployment has been detected as 'inactive'.*/).to_stdout
        end
      end

      context "when a CLI commands fails" do
        before do
          allow(bosh_list_deployments).to receive(:execute).and_raise(Tasks::Bosh::BoshCliError)
        end

        it "error" do
          expect { delete_plan.process }.
              to raise_error(Tasks::Bosh::BoshCliError)
        end
      end
    end
  end
end
