require 'spec_helper'
require 'tempfile'
require 'tasks'
require_relative '../../../concourse/tasks/bosh_delete_apply/delete_apply'

describe DeleteApply do
  let(:process_status_zero) { instance_double(Process::Status, exitstatus: 0) }
  let(:process_status_one) { instance_double(Process::Status, exitstatus: 1) }
  let(:error_filepath) { Tempfile.new }
  let(:bosh_list_deployments) { instance_double(Tasks::Bosh::ListDeployments) }
  let(:bosh_delete_deployment) { instance_double(Tasks::Bosh::DeleteDeployment) }

  describe ".process" do
    context "when the environment is not complete" do

      before { allow(ENV).to receive(:[]).and_return("") }
      after {}

      it "error" do
        err_msg = "missing environment variable: ROOT_DEPLOYMENT_NAME"
        expect { described_class.new.process }.
            to raise_error(Tasks::Bosh::EnvVarMissing, err_msg)
      end
    end

    context "when the environment is complete" do
      let(:delete_apply) { described_class.new(bosh_list_deployments, bosh_delete_deployment, config_repo_deployments) }
      let(:cmd_env) { { "BOSH_ENVIRONMENT" => "1.2.3.4" } }
      let(:root_depl_name) { 'my-root-depls' }
      let(:protected) { %w[p1 p2 p3] }
      let(:protected_paths) { protected.map { |name| File.join('xx', root_depl_name, name, 'protect-deployment.yml') } }
      let(:expected) { %w[a b c p1] }
      let(:expected_paths) { expected.map { |name| File.join('xx', root_depl_name, name, 'enable-deployment.yml') } }
      let(:deployed) { %w[d1 d2 d3] + expected }
      let(:config_repo_deployments) { instance_double(Tasks::ConfigRepo::Deployments) }

      before do
        allow(bosh_delete_deployment).to receive(:execute).and_return(nil)
        allow(config_repo_deployments).to receive(:enabled_deployments).and_return(expected)
        allow(config_repo_deployments).to receive(:protected_deployments).and_return(protected)
        allow(config_repo_deployments).to receive(:cleanup_disabled_deployments)
        allow(config_repo_deployments).to receive(:cleanup_deployment)
      end

      context "when all deployments are protected" do
        let(:protected) { %w[p1 p2 p3 d1 d2 d3] }

        it "does not delete anything" do
          allow(bosh_list_deployments).to receive(:execute).and_return(deployed)

          delete_apply.process

          expect(bosh_delete_deployment).not_to have_received(:execute)
          expect(bosh_list_deployments).to have_received(:execute)
        end
      end

      context "when directory is not empty" do

        before do
          allow(bosh_list_deployments).to receive(:execute).and_return(deployed)
          allow(Dir).to receive(:empty?).with(File.join('config-resource', root_depl_name, 'd1')).and_return(false)
        end

        it "keeps it" do
          delete_apply.process

          expect(bosh_delete_deployment).to have_received(:execute).with("d1")
          expect(config_repo_deployments).to have_received(:cleanup_deployment).with('d1')
        end
      end

      context "when multiple deployments processed" do
        it "deletes empty deployment directories" do
          allow(bosh_list_deployments).to receive(:execute).and_return(deployed)

          delete_apply.process

          expect(config_repo_deployments).to have_received(:cleanup_deployment).with('d1')
          expect(config_repo_deployments).to have_received(:cleanup_deployment).with('d2')
          expect(config_repo_deployments).to have_received(:cleanup_deployment).with('d3')
        end
      end

      context "when a CLI commands fails" do
        let(:stderr) { "e" }
        let(:stdout) { "o" }
        let(:error_message) {
          <<~TEXT
            Stderr: (Tasks::Bosh::BoshCliError)
            Stdout:
            {
                "Tables": null,
                "Blocks": [
                    "Deleting instances: worker/2f126d82-e8fc-4dc5-92d9-6a4f0f2bd883 (2)",
                    "\nTask 9264639 | 08:07:07 | ",
                    "Deleting instances: master/b01722bd-c732-45a4-a4ac-c29e6c124e9a (1)",
                    "\nTask 9264639 | 08:07:07 | ",
                    "Deleting instances: worker/94f3fbe5-7c27-4725-b681-a382b0aa784f (4)",
                    "\nTask 9264639 | 08:07:08 | ",
                    "Deleting instances: management/e3519ca5-0a79-4ac7-92b0-b52791e57a52 (0) (00:00:01)",
                    "\n                     L Error: Action Failed get_task: Task c3c9f620-f0fd-490d-580c-0bb639e8b767 result: 1 of 2 pre-stop scripts failed. Failed Jobs: action. Successful Jobs: management.",
                    "\nTask 9264639 | 08:08:35 | ",
                    "Deleting instances: worker/2f126d82-e8fc-4dc5-92d9-6a4f0f2bd883 (2) (00:01:28)",
                    "\nTask 9264639 | 08:08:40 | ",
                    "Deleting instances: worker/4c9c9065-d723-410e-8fa7-b28c09277a61 (0) (00:01:56)",
                    "\nTask 9264639 | 08:09:03 | ",
                    "Error: Action Failed get_task: Task c3c9f620-f0fd-490d-580c-0bb639e8b767 result: 1 of 2 pre-stop scripts failed. Failed Jobs: action. Successful Jobs: management."
                ],
                "Lines": [
                    "Using environment '192.168.99.155' as client 'admin'",
                    "Using deployment 'k_7bd80932-4d39-4fb9-969a-2445ade2495d'",
                    "Task 9264639",
                    "\n",
                    "\n\nTask 9264639 Started  Tue Feb 25 08:07:07 UTC 2020\nTask 9264639 Finished Tue Feb 25 08:09:03 UTC 2020\nTask 9264639 Duration 00:01:56",
                    "\nTask 9264639 error\n",
                    "Deleting deployment 'k_7bd80932-4d39-4fb9-969a-2445ade2495d':\n  Expected task '9264639' to succeed but state is 'error'",
                    "Exit code 1"
                ]
            }
          TEXT
        }

        before do
          allow(bosh_list_deployments).to receive(:execute).and_return(%w[a b c d1 d2 d3])
          allow(bosh_delete_deployment).to receive(:execute).and_raise(Tasks::Bosh::BoshCliError, error_message)
        end

        it "error" do
          expect { delete_apply.process }.
            to raise_error(Tasks::Bosh::BoshCliError, "Failed to delete deployments: [\"d1\", \"d2\", \"d3\"]")
        end
      end
    end
  end
end
