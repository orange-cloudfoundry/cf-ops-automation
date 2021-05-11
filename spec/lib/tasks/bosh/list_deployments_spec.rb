require 'tempfile'
require 'rspec'
require 'tasks'

describe Tasks::Bosh::ListDeployments do
  let(:process_status_zero) { instance_double(Process::Status, exitstatus: 0) }
  let(:process_status_one) { instance_double(Process::Status, exitstatus: 1) }
  let(:error_filepath) { Tempfile.new }
  let(:deployments_json) do
    ' {
          "Tables": [
              {
                  "Content": "deployments",
                  "Header": {
                      "name": "Name",
                      "release_s": "Release(s)",
                      "stemcell_s": "Stemcell(s)",
                      "team_s": "Team(s)"
                  },
                  "Rows": [
                      { "name": "concourse",
                          "release_s": "bosh-dns/1.11.0\nbpm/1.1.5\nconcourse/5.3.0\ngeneric-scripting/2\nhaproxy/9.8.0\nminio/2019-06-27T21-13-50Z\nnode-exporter/4.2.0\nos-conf/21.0.0\npostgres/39\nprometheus/26.1.0\nrouting/0.195.0\nshield/8.5.0\nsyslog/11.6.0\nturbulence/0.10.0+dev.2",
                          "stemcell_s": "bosh-openstack-kvm-ubuntu-bionic-go_agent/456.69",
                          "team_s": "" },
                      { "name": "credhub-ha",
                          "release_s": "bpm/1.1.5\ncredhub/2.5.6\nhaproxy/9.8.0\nnode-exporter/4.2.0\nos-conf/21.0.0\npostgres/39\nshield/7.0.2\nsyslog/11.6.0\nuaa/74.8.0",
                          "stemcell_s": "bosh-openstack-kvm-ubuntu-bionic-go_agent/456.77",
                          "team_s": "" },
                      {
                          "name": "dns-recursor",
                          "release_s": "bosh-dns/1.11.0\nbpm/1.1.5\nnode-exporter/4.2.0\nntp/4.2.8p12\nos-conf/21.0.0\nsyslog/11.6.0",
                          "stemcell_s": "bosh-openstack-kvm-ubuntu-bionic-go_agent/456.77",
                          "team_s": ""
                      },
                      {
                          "name": "docker-bosh-cli",
                          "release_s": "bosh-dns/1.11.0\nbpm/1.1.5\ncron/1.1.3\ndocker/35.3.4\ngeneric-scripting/2\nnode-exporter/4.2.0\nos-conf/21.0.0\nrouting/0.195.0\nsyslog/11.6.0\nweave-scope/0.0.18",
                          "stemcell_s": "bosh-openstack-kvm-ubuntu-bionic-go_agent/456.77",
                          "team_s": ""
                      },
                      {
                          "name": "gitlab",
                          "release_s": "bosh-dns/1.11.0\nbpm/1.1.5\ndocker/35.3.4\ngeneric-scripting/2\nminio/2019-06-27T21-13-50Z\nnode-exporter/4.2.0\nos-conf/21.0.0\nrouting/0.195.0\nshield/8.5.0\nsyslog/11.6.0\nweave-scope/0.0.18",
                          "stemcell_s": "bosh-openstack-kvm-ubuntu-bionic-go_agent/456.77",
                          "team_s": ""
                      },
                      {
                          "name": "minio-private-s3",
                          "release_s": "bosh-dns/1.11.0\nbpm/1.1.5\nhaproxy/9.8.0\nminio/2019-06-27T21-13-50Z\nnode-exporter/4.2.0\nos-conf/21.0.0\nrouting/0.195.0\nsyslog/11.6.0\nweave-scope/0.0.18",
                          "stemcell_s": "bosh-openstack-kvm-ubuntu-bionic-go_agent/456.77",
                          "team_s": ""
                      },
                      {
                          "name": "prometheus-exporter-master",
                          "release_s": "bosh-dns/1.11.0\nbosh-dns-aliases/0.0.3\nbpm/1.1.5\nnode-exporter/4.2.0\nos-conf/21.0.0\nprometheus/26.1.0\nrouting/0.195.0\nsyslog/11.6.0\nweave-scope/0.0.18",
                          "stemcell_s": "bosh-openstack-kvm-ubuntu-bionic-go_agent/456.77",
                          "team_s": ""
                      }
                  ],
                  "Notes": null
              }
          ],
          "Blocks": null,
          "Lines": [
              "Using environment \'192.168.1.1\' as user \'xxxx\'",
              "Succeeded"
          ]
      }'
  end
  let(:loaded_json) { JSON.parse(deployments_json) }

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
        let(:expected_deployments) { %w(concourse credhub-ha dns-recursor docker-bosh-cli gitlab minio-private-s3 prometheus-exporter-master) }

        before do
          allow(Open3).to receive(:capture3).with(cmd_env, "bosh deployments --json").
              and_return([deployments_json, nil, process_status_zero])
        end

        it "executes a bosh command" do
          expect(command_output).to match(expected_deployments)

          expect(Open3).to have_received(:capture3).with(cmd_env, "bosh deployments --json")
        end
      end

      context "when a CLI command fails" do
        let(:stderr) { "e" }
        let(:stdout) { "o" }

        before do
          allow(Open3).to receive(:capture3).with(cmd_env, "bosh deployments --json").once.
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
