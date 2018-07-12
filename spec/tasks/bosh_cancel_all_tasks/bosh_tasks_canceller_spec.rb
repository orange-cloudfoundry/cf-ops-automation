require 'spec_helper'
require 'tempfile'
require_relative '../../../concourse/tasks/bosh_cancel_all_tasks/bosh_tasks_canceller'

describe BoshTasksCanceller do
  let(:process_status_zero) { double(Process::Status, exitstatus: 0) }
  let(:process_status_one) { double(Process::Status, exitstatus: 1) }
  let(:error_filepath) { Tempfile.new }

  before do
    allow(BoshTasksCanceller).to receive(:error_filepath).and_return(error_filepath)
  end

  describe ".execute" do
    context "when the environment is not complete" do
      before { allow(ENV).to receive(:[]).and_return(nil) }
      after {}

      it "error" do
        err_msg = "The environment is missing env vars for this task to be able to work properly."
        expect { BoshTasksCanceller.new.execute }.
          to raise_error(BoshTasksCanceller::EnvVarMissing, err_msg)
      end
    end

    context "when the environment is complete" do
      let(:tasks_json) do
        <<~TASKS
          {
              "Tables": [
                  {
                      "Content": "tasks",
                      "Header": {
                          "deployment": "Deployment",
                          "description": "Description",
                          "id": "ID",
                          "last_activity_at": "Last Activity At",
                          "result": "Result",
                          "started_at": "Started At",
                          "state": "State",
                          "user": "User"
                      },
                      "Rows": [
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
                          }
                      ],
                      "Notes": null
                  }
              ],
              "Blocks": null,
              "Lines": [
                  "Using environment '192.168.50.6' as user 'admin' (openid, bosh.admin)",
                  "Succeeded"
              ]
          }
        TASKS
      end

      before do
        %w[BOSH_ENVIRONMENT BOSH_CLIENT BOSH_CLIENT_SECRET BOSH_CA_CERT].each do |arg|
          allow(ENV).to receive(:[]).with(arg).and_return(arg.downcase)
        end
      end

      context "when all CLI commands run successfully" do
        before do
          allow(Open3).to receive(:capture3).with("bosh tasks --json").once.
            and_return([tasks_json, nil, process_status_zero])
          allow(Open3).to receive(:capture3).with("bosh cancel-task 19").
            and_return(["", nil, process_status_zero])
        end

        it "run the bosh cancel-task command on processing tasks" do
          BoshTasksCanceller.new.execute

          expect(Open3).to have_received(:capture3).with("bosh cancel-task 19")
          expect(Open3).not_to have_received(:capture3).with("bosh cancel-task 20")
        end
      end

      context "when a CLI commands fails" do
        let(:stderr) { "e" }
        let(:stdout) { "o" }

        before do
          allow(Open3).to receive(:capture3).with("bosh tasks --json").once.
            and_return([tasks_json, nil, process_status_zero])
          allow(Open3).to receive(:capture3).with("bosh cancel-task 19").
            and_return([stdout, stderr, process_status_one])
        end

        it "error" do
          expect { BoshTasksCanceller.new.execute }.
            to raise_error(BoshTasksCanceller::BoshCliError, "Stderr:\n#{stderr}\nStdout:\n#{stdout}")
        end
      end
    end
  end
end
