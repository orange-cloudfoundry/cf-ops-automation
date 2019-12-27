require 'tempfile'
require 'rspec'
require 'tasks/bosh'

describe Tasks::Bosh::Executor do
  let(:process_status_zero) { instance_double(Process::Status, exitstatus: 0) }
  let(:process_status_one) { instance_double(Process::Status, exitstatus: 1) }
  let(:error_filepath) { Tempfile.new }
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
  let(:loaded_json) { JSON.parse(tasks_json) }

  before do
    allow(described_class).to receive(:error_filepath).and_return(error_filepath)
  end

  describe ".run_command" do
    context "when the environment is not complete" do
      before { allow(ENV).to receive(:[]).and_return("") }

      after {}

      it "error" do
        err_msg = "The environment is missing env vars for this task to be able to work properly."
        expect { described_class.run_command("bosh deployments") }.
          to raise_error(Tasks::Bosh::EnvVarMissing, err_msg)
      end
    end

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
        let(:command_output) { described_class.run_command("bosh tasks --json") }

        before do
          allow(Open3).to receive(:capture3).with(cmd_env, "bosh tasks --json").
            and_return([tasks_json, nil, process_status_zero])
        end

        it "executes a bosh command" do
          expect(command_output).to match(loaded_json)

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
          expect { described_class.run_command("bosh tasks --json") }.
            to raise_error(Tasks::Bosh::BoshCliError, "Stderr:\n#{stderr}\nStdout:\n#{stdout}")
        end
      end
    end
  end

  describe ".filter_table_result" do
    context "when no filter is provided" do
      it "returns unfiltered content" do
        expect(described_class.filter_table_result(loaded_json)).to match(loaded_json)
      end
    end

    context "when nothing match provided filter" do
      let(:expected_result) { {"Blocks"=>nil, "Lines"=>["Using environment '192.168.50.6' as user 'admin' (openid, bosh.admin)", "Succeeded"], "Tables"=>[]} }
      it "returns an empty content" do
        expect(described_class.filter_table_result(loaded_json, "deployments")).to match(expected_result)
      end
    end

    context "when filter match value" do
      it "returns matching value" do
        expect(described_class.filter_table_result(loaded_json, "tasks")).to match(loaded_json)
      end
    end
  end

  describe ".rows" do
    context "when a valid bosh json result is processed" do
      let(:expected_rows) do
        JSON.parse <<~JSON
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
        JSON
      end

      it "returns expected result" do
        expect(described_class.rows(loaded_json)).to match(expected_rows)
      end
    end

    context "when nothing match provided filter" do
      let(:loaded_json) { JSON.parse '{"my": "dummy"}' }
      it "returns an empty content" do
        expect(described_class.rows(loaded_json)).to be_empty
      end
    end
  end
end
