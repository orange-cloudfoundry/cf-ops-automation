require 'tempfile'
require 'rspec'
require 'tasks'

describe Tasks::Bosh::DeleteDeployment do
  let(:process_status_zero) { instance_double(Process::Status, exitstatus: 0) }
  let(:process_status_one) { instance_double(Process::Status, exitstatus: 1) }
  let(:error_filepath) { Tempfile.new }
  let(:my_deployment_name) { 'my-deployment-name' }
  let(:delete_deployment_json_response) do
    '{
      "Tables": null,
      "Blocks": null,
      "Lines": [
          "Using environment \'192.168.1.1\' as user \'my-user\'",
          "Using deployment ' + my_deployment_name + '",
          "Succeeded"
      ]
    }'
  end
  let(:delete_deployment_response) { JSON.parse(delete_deployment_json_response) }

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
        let(:command_output) { described_class.new.execute(my_deployment_name) }
        let(:expected_result) { delete_deployment_response }

        before do
          allow(Open3).to receive(:capture3).with(cmd_env, "bosh delete-deployment --json --non-interactive -d #{my_deployment_name} --force").
            and_return([delete_deployment_json_response, nil, process_status_zero])
        end

        it "executes a bosh command" do
          expect(command_output).to match(expected_result)

          expect(Open3).to have_received(:capture3).with(cmd_env, "bosh delete-deployment --json --non-interactive -d #{my_deployment_name} --force")
        end
      end

      context "when a CLI command fails" do
        let(:stderr) { "e" }
        let(:stdout) { "o" }

        before do
          allow(Open3).to receive(:capture3).with(cmd_env, "bosh delete-deployment --json --non-interactive -d #{my_deployment_name} --force").once.
              and_return([stdout, stderr, process_status_one])
        end

        it "error" do
          expect { described_class.new.execute(my_deployment_name) }.
              to raise_error(Tasks::Bosh::BoshCliError, "Stderr:\n#{stderr}\nStdout:\n#{stdout}")
        end
      end
    end
  end
end
