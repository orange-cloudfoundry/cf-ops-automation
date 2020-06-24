require 'tempfile'
require 'rspec'
require 'tasks'

describe Tasks::Bosh::ListReleases do
  let(:process_status_zero) { instance_double(Process::Status, exitstatus: 0) }
  let(:process_status_one) { instance_double(Process::Status, exitstatus: 1) }
  let(:error_filepath) { Tempfile.new }
  let(:releases_json) do
  ' {
      "Tables": [
          {
              "Content": "releases",
              "Header": { "commit_hash": "Commit Hash", "name": "Name", "version": "Version" },
              "Rows": [
                  {
                      "commit_hash": "f7138d2",
                      "name": "backup-and-restore-sdk",
                      "version": "1.17.2*"
                  },
                  {
                      "commit_hash": "ead4ff2",
                      "name": "bosh",
                      "version": "270.11.0*"
                  },
                  {
                      "commit_hash": "e6dc502",
                      "name": "prometheus",
                      "version": "26.2.0*"
                  },
                  {
                      "commit_hash": "55b2ace",
                      "name": "prometheus",
                      "version": "26.1.0"
                  },
                  {
                      "commit_hash": "7709fe4",
                      "name": "routing",
                      "version": "0.195.0"
                  },
                  {
                      "commit_hash": "265671b5",
                      "name": "shell",
                      "version": "3.2.0"
                  },
                  {
                      "commit_hash": "db113bf",
                      "name": "shield",
                      "version": "8.6.3*"
                  },
                  {
                      "commit_hash": "1c68eea",
                      "name": "shield",
                      "version": "8.6.2"
                  },
                  {
                      "commit_hash": "a88e5e0+",
                      "name": "store",
                      "version": "0+dev.2*"
                  },
                  {
                      "commit_hash": "a88e5e0+",
                      "name": "store",
                      "version": "0+dev.1"
                  },
                  {
                      "commit_hash": "05c4109",
                      "name": "uaa",
                      "version": "74.16.0*"
                  },
                  {
                      "commit_hash": "f5a81d2",
                      "name": "uaa",
                      "version": "74.13.0*"
                  },
                  {
                      "commit_hash": "c0f662e",
                      "name": "uaa",
                      "version": "74.8.0"
                  }
              ],
            "Notes": [
                "(*) Currently deployed",
                "(+) Uncommitted changes"
            ]
        }
    ],
    "Blocks": null,
    "Lines": [
        "Using environment \'192.168.1.1\' as user \'xxxxx\'",
        "Succeeded"
    ]
    }'
  end
  let(:loaded_json) { JSON.parse(releases_json) }

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
        let(:expected_releases) do
          { "backup-and-restore-sdk" => { "1.17.2" => { commit_hash: "f7138d2", deployed: true, uncommitted_changes: false } },
            "bosh" => { "270.11.0" => { commit_hash: "ead4ff2", deployed: true, uncommitted_changes: false } },
            "prometheus" => { "26.1.0" => { commit_hash: "55b2ace", deployed: false, uncommitted_changes: false }, "26.2.0" => { commit_hash: "e6dc502", deployed: true, uncommitted_changes: false } },
            "routing" => { "0.195.0" => { commit_hash: "7709fe4", deployed: false, uncommitted_changes: false } },
            "shell" => { "3.2.0" => { commit_hash: "265671b5", deployed: false, uncommitted_changes: false } },
            "shield" => { "8.6.2" => { commit_hash: "1c68eea", deployed: false, uncommitted_changes: false }, "8.6.3"     => {commit_hash: "db113bf", deployed: true, uncommitted_changes: false } },
            "store" => { "0+dev.1" => { commit_hash: "a88e5e0+", deployed: false, uncommitted_changes: false }, "0+dev.2" => {commit_hash: "a88e5e0+", deployed: true, uncommitted_changes: false } },
            "uaa" => { "74.13.0" => { commit_hash: "f5a81d2", deployed: true, uncommitted_changes: false }, "74.16.0"     => {commit_hash: "05c4109", deployed: true, uncommitted_changes: false }, "74.8.0" => {commit_hash: "c0f662e", deployed: false, uncommitted_changes: false } }
          }
        end

        before do
          allow(Open3).to receive(:capture3).with(cmd_env, "bosh releases --json")
            .and_return([releases_json, nil, process_status_zero])
        end

        it "executes a bosh command" do
          expect(command_output).to match(expected_releases)

          expect(Open3).to have_received(:capture3).with(cmd_env, "bosh releases --json")
        end
      end

      context "when a CLI command fails" do
        let(:stderr) { "e" }
        let(:stdout) { "o" }

        before do
          allow(Open3).to receive(:capture3).with(cmd_env, "bosh releases --json").once.
            and_return([stdout, stderr, process_status_one])
        end

        it "error" do
          expect { described_class.new.execute }.
            to raise_error(Tasks::Bosh::BoshCliError, "Stderr:\n#{stderr}\nStdout:\n#{stdout}")
        end
      end
    end
  end
end
