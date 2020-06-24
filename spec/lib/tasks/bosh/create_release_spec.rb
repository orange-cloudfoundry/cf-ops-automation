require 'tempfile'
require 'rspec'
require 'tasks'

describe Tasks::Bosh::CreateRelease do
  let(:process_status_zero) { instance_double(Process::Status, exitstatus: 0) }
  let(:process_status_one) { instance_double(Process::Status, exitstatus: 1) }
  let(:error_filepath) { Tempfile.new }
  let(:create_release_json) do
  '
    {
        "Tables": [
            {
                "Content": "",
                "Header": {
                    "archive": "Archive",
                    "commit_hash": "Commit Hash",
                    "name": "Name",
                    "version": "Version"
                },
                "Rows": [
                    {
                        "archive": "/data/ntp.tgz",
                        "commit_hash": "6263f00",
                        "name": "ntp",
                        "version": "4.2.8p11"
                    }
                ],
                "Notes": null
            },
            {
                "Content": "jobs",
                "Header": {
                    "digest": "Digest",
                    "job": "Job",
                    "packages": "Packages"
                },
                "Rows": [
                    {
                        "digest": "672b4254f375426f71fcb0efcc48501a11d14877",
                        "job": "ntpd/ed8ef1c60e84f1032a3a31efc33ebbd43a54cea4",
                        "packages": ""
                    },
                    {
                        "digest": "e10f673c371b6c39596dfb31c6e6cca11ef8dc60",
                        "job": "ntpd_server/7368613c4ebaaedfe5b60d2cd257684a96866680",
                        "packages": ""
                    }
                ],
                "Notes": null
            },
            {
                "Content": "packages",
                "Header": {
                    "dependencies": "Dependencies",
                    "digest": "Digest",
                    "package": "Package"
                },
                "Rows": [
                    {
                        "dependencies": "",
                        "digest": "16048e381126e09254ec3a587e9bbbf0547e5e65",
                        "package": "ntp/1e405850263e427c840b0f6a899760232983f8c3"
                    }
                ],
                "Notes": null
            }
        ],
        "Blocks": null,
        "Lines": [
            "Succeeded"
        ]
    }
  '
  end
  let(:loaded_json) { JSON.parse(create_release_json) }

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
        let(:command_output) { described_class.new.execute(name: 'ntp', version: '4.2.8p11', dir: '/tmp/my-workdir/ntp-release', tarball_path: '/tmp/releases') }
        let(:expected_releases) do
          loaded_json
        end

        before do
          allow(Open3).to receive(:capture3).with(cmd_env, "bosh --non-interactive --json create-release --dir='/tmp/my-workdir/ntp-release' --final --tarball='/tmp/releases/ntp-4.2.8p11.tgz' /tmp/my-workdir/ntp-release/releases/ntp/ntp-4.2.8p11.yml")
            .and_return([create_release_json, nil, process_status_zero])
        end

        it "executes a bosh command" do
          expect(command_output).to match(expected_releases)

          expect(Open3).to have_received(:capture3).with(cmd_env, "bosh --non-interactive --json create-release --dir='/tmp/my-workdir/ntp-release' --final --tarball='/tmp/releases/ntp-4.2.8p11.tgz' /tmp/my-workdir/ntp-release/releases/ntp/ntp-4.2.8p11.yml")
        end
      end

      context "when a CLI command fails" do
        let(:stderr) { "e" }
        let(:stdout) { "o" }

        before do
          allow(Open3).to receive(:capture3).with(cmd_env, "bosh --non-interactive --json create-release --dir='.' --tarball='/tmp/releases/ntp-4.2.8p11.tgz' --force ./releases/ntp/ntp-4.2.8p11.yml").once.
            and_return([stdout, stderr, process_status_one])
        end

        it "error" do
          expect { described_class.new.execute(name: 'ntp', version: '4.2.8p11', tarball_path: '/tmp/releases', final: false, force: true) }.
            to raise_error(Tasks::Bosh::BoshCliError, "Stderr:\n#{stderr}\nStdout:\n#{stdout}")
        end
      end
    end
  end
end
