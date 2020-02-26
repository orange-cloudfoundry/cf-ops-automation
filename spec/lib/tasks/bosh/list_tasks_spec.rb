require 'tempfile'
require 'rspec'
require 'tasks'

describe Tasks::Bosh::ListTasks do
  let(:process_status_zero) { instance_double(Process::Status, exitstatus: 0) }
  let(:process_status_one) { instance_double(Process::Status, exitstatus: 1) }
  let(:error_filepath) { Tempfile.new }
  let(:tasks_json_response) do
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
  let(:tasks_response) { JSON.parse(tasks_json_response) }

  before do
    allow(described_class).to receive(:error_filepath).and_return(error_filepath)
  end

  describe ".execute" do
    context "when the environment is complete" do
      let(:cmd_env) { { "BOSH_ENVIRONMENT" => "1.2.3.4" } }

      before do
        %w[BOSH_TARGET BOSH_CLIENT BOSH_CLIENT_SECRET BOSH_CA_CERT].each do |arg|
          if arg == "BOSH_TARGET"
            allow(ENV).to receive(:[]).with(arg).and_return("1.2.3.4")
          else
            allow(ENV).to receive(:[]).with(arg).and_return(arg.downcase)
          end
        end
      end

      context "when a CLI command runs successfully" do
        let(:command_output) { described_class.new.execute }
        let(:task_ids) { command_output&.map { |task_details| task_details&.dig('id') } }
        let(:expected_task_ids) { %w[19 20 21] }

        before do
          allow(Open3).to receive(:capture3).with(cmd_env, "bosh tasks --json").
            and_return([tasks_json_response, nil, process_status_zero])
        end

        it "executes a bosh command" do
          expect(task_ids).to match(expected_task_ids)

          expect(Open3).to have_received(:capture3).with(cmd_env, "bosh tasks --json")
        end
      end

      context "when a CLI command fails" do
        let(:stderr) { "e" }
        let(:stdout) { "o" }

        before do
          allow(Open3).to receive(:capture3).with(cmd_env, "bosh tasks --json").once.
            and_return([stdout, stderr, process_status_one])
        end

        it "error" do
          expect { described_class.new.execute }.
            to raise_error(Tasks::Bosh::BoshCliError, "Stderr:\n#{stderr}\nStdout:\n#{stdout}")
        end
      end

      context "when no tasks are found" do
        let(:tasks_json_response) do
          <<~EMPTY_TASKS
            {
                "Tables": [
                    {
                        "Content": "tasks",
                        "Header": {
                            "deployment": "Deployment",
                            "description": "Description",
                            "finished_at": "Finished At",
                            "id": "ID",
                            "result": "Result",
                            "started_at": "Started At",
                            "state": "State",
                            "user": "User"
                        },
                        "Rows": [],
                        "Notes": null
                    }
                ],
                "Blocks": null,
                "Lines": [
                    "Using environment '192.168.99.155' as user 'oorand'",
                    "Succeeded"
                ]
            }
          EMPTY_TASKS
        end
        let(:command_output) { described_class.new.execute }
        let(:task_ids) { command_output&.map { |task_details| task_details&.dig('id') } }
        let(:expected_task_ids) { [] }

        before do
          allow(Open3).to receive(:capture3).with(cmd_env, "bosh tasks --json").
            and_return([tasks_json_response, nil, process_status_zero])
        end

        it "executes a bosh command" do
          expect(task_ids).to match(expected_task_ids)

          expect(Open3).to have_received(:capture3).with(cmd_env, "bosh tasks --json")
        end
      end
    end
  end
end
