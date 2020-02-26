require 'spec_helper'
require 'tempfile'
require 'tasks'
require_relative '../../../concourse/tasks/bosh_cancel_all_tasks/bosh_tasks_canceller'

describe BoshTasksCanceller do
  let(:process_status_zero) { double(Process::Status, exitstatus: 0) }
  let(:process_status_one) { double(Process::Status, exitstatus: 1) }
  let(:bosh_list_tasks) { instance_double(Tasks::Bosh::ListTasks) }
  let(:bosh_cancel_task) { instance_double(Tasks::Bosh::CancelTask) }
  let(:error_filepath) { Tempfile.new }
  let(:tasks_canceller) { described_class.new(bosh_list_tasks, bosh_cancel_task) }

  before do
    allow(BoshTasksCanceller).to receive(:error_filepath).and_return(error_filepath)
  end

  describe ".process" do
    context "when the environment is complete" do
      let(:list_tasks_json_response) do
        <<~TASKS
          [
              {
                  "deployment": "",
                  "description": "delete stemcell: bosh-warden-boshlite-ubuntu-trusty-go_agent/3586.26",
                  "id": "19",
                  "last_activity_at": "Wed Aug  1 11:53:58 UTC 2018",
                  "result": "",
                  "started_at": "Wed Aug  1 11:53:58 UTC 2018",
                  "state": "processing",
                  "user": "admin"
              },
              {
                  "deployment": "",
                  "description": "delete stemcell: bosh-warden-boshlite-ubuntu-trusty-go_agent/3586.25",
                  "id": "20",
                  "last_activity_at": "Wed Aug  1 11:53:58 UTC 2018",
                  "result": "",
                  "started_at": "Wed Aug  1 11:53:58 UTC 2018",
                  "state": "cancelled",
                  "user": "admin"
              },
              {
                  "deployment": "",
                  "description": "create release",
                  "id": "21",
                  "last_activity_at": "Wed Oct 17 14:53:22 UTC 2018",
                  "result": "",
                  "started_at": "Thu Jan  1 00:00:00 UTC 1970",
                  "state": "queued",
                  "user": "admin"
              }
          ]
        TASKS
      end
      let(:list_tasks_response) { JSON.parse list_tasks_json_response }

      before do
        %w[BOSH_TARGET BOSH_CLIENT BOSH_CLIENT_SECRET BOSH_CA_CERT].each do |arg|
          if arg == "BOSH_TARGET"
            allow(ENV).to receive(:[]).with(arg).and_return("1.2.3.4")
          else
            allow(ENV).to receive(:[]).with(arg).and_return(arg.downcase)
          end
        end
      end

      context "when all CLI commands run successfully" do
        before do
          allow(bosh_list_tasks).to receive(:execute).once.
            and_return(list_tasks_response)
          allow(bosh_cancel_task).to receive(:execute)
        end

        it "run the bosh cancel-task command on processing tasks" do
          tasks_canceller.process

          expect(bosh_list_tasks).to have_received(:execute)
          expect(bosh_cancel_task).to have_received(:execute).with("19")
          expect(bosh_cancel_task).to have_received(:execute).with("21")
          expect(bosh_cancel_task).not_to have_received(:execute).with("20")
        end
      end

      context "when a cancel task commands fails" do
        let(:stderr) { "e" }
        let(:stdout) { "o" }
        let(:error_message) { "Stderr:\n#{stderr}\nStdout:\n#{stdout}" }

        before do
          allow(bosh_list_tasks).to receive(:execute).once.
            and_return(list_tasks_response)
          allow(bosh_cancel_task).to receive(:execute).
            and_raise(Tasks::Bosh::BoshCliError, error_message)
        end

        it "stops on first error" do
          expect { tasks_canceller.process }.
            to raise_error(Tasks::Bosh::BoshCliError, "Stderr:\n#{stderr}\nStdout:\n#{stdout}")

          expect(bosh_list_tasks).to have_received(:execute).once
          expect(bosh_cancel_task).to have_received(:execute).once
        end
      end

      context "when a list task commands fails" do
        let(:stderr) { "e" }
        let(:stdout) { "o" }
        let(:error_message) { "Stderr:\n#{stderr}\nStdout:\n#{stdout}" }

        before do
          allow(bosh_list_tasks).to receive(:execute).once.
            and_raise(Tasks::Bosh::BoshCliError, error_message)
          allow(bosh_cancel_task).to receive(:execute)
        end

        it "stops on first error" do
          expect { tasks_canceller.process }.
            to raise_error(Tasks::Bosh::BoshCliError, "Stderr:\n#{stderr}\nStdout:\n#{stdout}")

          expect(bosh_list_tasks).to have_received(:execute).once
          expect(bosh_cancel_task).not_to have_received(:execute)
        end
      end
    end
  end
end
