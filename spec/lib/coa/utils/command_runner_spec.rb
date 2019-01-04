require 'spec_helper'
require 'coa/utils/command_runner'

describe Coa::Utils::CommandRunner do
  before do
    status = instance_double("Process::Status", "success?" => true)
    allow(Open3).to receive(:capture3).
      and_return(["", "", status])
  end

  # TODO: use shared_examples
  describe '#execute' do
    let(:cmd) { "ls" }

    context "when no option is provided" do
      let(:runner) { described_class.new(cmd) }

      it "executes the given command" do
        runner.execute

        expect(Open3).to have_received(:capture3).with(cmd)
      end
    end

    context "when a profile is given" do
      let(:profile) { "ls" }
      let(:runner) { described_class.new(cmd, profile: profile) }
      let(:file) { instance_double("Tempfile") }

      it "load the profile and executes the given command" do
        allow(Tempfile).to receive(:new).and_return(file)
        allow(file).to receive(:write)
        allow(file).to receive(:close)
        allow(file).to receive(:path)
        allow(file).to receive(:unlink)

        runner.execute

        expect(Tempfile).to have_received(:new)
        expect(file).to have_received(:write).with(profile)

        expect(Open3).to have_received(:capture3).
          with(". #{file.path} && #{cmd}")
      end
    end

    context "when the fail_silently option is true" do
      let(:runner) { described_class.new(cmd, fail_silently: true) }

      it "executes the given command" do
        runner.execute

        expect(Open3).to have_received(:capture3).with(cmd)
      end
    end

    context "when the verbose option is true" do
      let(:runner) { described_class.new(cmd, verbose: true) }

      it "executes the given command" do
        runner.execute

        expect(Open3).to have_received(:capture3).with(cmd)
      end
    end
  end
end
