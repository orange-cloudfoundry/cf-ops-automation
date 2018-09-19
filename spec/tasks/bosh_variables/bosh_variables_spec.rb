require 'spec_helper'
require 'tempfile'
require_relative '../../../concourse/tasks/bosh_variables/bosh_variables_executor'

describe BoshVariablesExecutor do
  let(:executor) { described_class.new }
  let(:process_status_zero) { double(Process::Status, exitstatus: 0) }
  let(:process_status_one) { double(Process::Status, exitstatus: 1) }
  let(:error_filepath) { Tempfile.new }
  let(:result_filepath) { Tempfile.new }

  before do
    allow(BoshVariablesExecutor).to receive(:error_filepath).and_return(error_filepath)
    allow(BoshVariablesExecutor).to receive(:result_filepath).and_return(result_filepath)
  end

  describe ".execute" do
    context "when the environment is not complete" do
      before { allow(ENV).to receive(:[]).and_return(nil) }
      after {}

      it "error" do
        err_msg = "The environment is missing env vars for this task to be able to work properly."
        expect {executor.execute }.
          to raise_error(BoshVariablesExecutor::EnvVarMissing, err_msg)
      end
    end

    context "when the environment is complete" do

      before do
        %w[BOSH_TARGET BOSH_CLIENT BOSH_CLIENT_SECRET BOSH_CA_CERT BOSH_DEPLOYMENT].each do |arg|
          allow(ENV).to receive(:[]).with(arg).and_return(arg.downcase)
        end
      end

      context "when all CLI commands run successfully" do
        let(:executor) { described_class.new }
        let(:stderr) { "" }
        let(:stdout) { "whatever message" }

        before do
          allow(Open3).to receive(:capture3).with(%(bash -ec "source ./scripts-resource/scripts/bosh_cli_v2_login.sh ${BOSH_TARGET}; bosh variables --json > #{result_filepath}")).once.
            and_return([stdout, stderr, process_status_zero])
        end

        it "runs the bosh variables task command" do
          executor.execute

          expect(Open3).to have_received(:capture3).with(%(bash -ec "source ./scripts-resource/scripts/bosh_cli_v2_login.sh ${BOSH_TARGET}; bosh variables --json > #{result_filepath}"))
          expect(ENV).not_to have_received(:[]).with('BOSH_ENVIRONMENT')
        end

        it "does not generate an error log file" do
          executor.execute
          expect(File).to be_zero(error_filepath)
        end

      end

      context "when a CLI commands fails" do
        let(:stderr) { "e" }
        let(:stdout) { "o" }

        before do
          allow(Open3).to receive(:capture3).with(%(bash -ec "source ./scripts-resource/scripts/bosh_cli_v2_login.sh ${BOSH_TARGET}; bosh variables --json > #{result_filepath}")).once.
            and_return([stdout, stderr, process_status_one])
        end

        it "generates an error and a error log file" do
          expect { executor.execute }.
            to raise_error(BoshVariablesExecutor::BoshCliError, "Stderr:\n#{stderr}\nStdout:\n#{stdout}")
          expect(File).not_to be_zero(error_filepath)
        end
      end
    end
  end
end
