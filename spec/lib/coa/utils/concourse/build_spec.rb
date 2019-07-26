require 'spec_helper'
require 'coa/utils/concourse'

describe Coa::Utils::Concourse::Build do
  let(:fly)      { instance_double("Coa::Utils::Concourse::Fly") }
  let(:pipeline) { instance_double("Coa::Utils::Concourse::Pipeline", pause: true) }
  let(:job)      { instance_double("Coa::Utils::Concourse::Job", fullname: "p1/j1", pipeline: pipeline ) }

  before do
    stub_const("#{described_class}::MAX_RETRIES", 2)
    allow(build).to receive(:sleep)
  end

  describe '#watch'

  describe '#follow_to_completion' do
    let(:build) { described_class.new(job: job) }

    context "when the jobs has succeeded" do
      let(:build_response) { "34455  p1/j1  1  succeeded  2018-12-14@09:27:20+0000  n/a  17m33s+" }

      it "returns a build directly" do
        allow(job).to receive(:raw_builds).and_return(build_response)

        build.follow_to_completion

        expect(job).to have_received(:raw_builds).once
        expect(build.status).to eq("succeeded")
      end
    end

    context "when the job has not succeeded" do
      let(:build_response) { "34455  p1/j1  1  started  2018-12-14@09:27:20+0000  n/a  17m33s+" }

      it "retries" do
        allow(job).to receive(:raw_builds).and_return(build_response)

        build.follow_to_completion

        expect(job).to have_received(:raw_builds).twice
        expect(build.status).to eq("started")
      end
    end
  end

  describe '#handle_result' do
    context "when a failure happened" do
      let(:status) { "errored" }
      let(:build) { described_class.new(job: job, status: status) }

      context "when the failure is ignored"  do
        it "just logs the final status" do
          logger = build.logger
          allow(logger).to receive(:log_and_puts)
          allow(pipeline).to receive(:pause)

          #expect{ build.handle_result(true) }.to_not raise_error(SystemExit)
          build.handle_result(true)

          expect(logger).to have_received(:log_and_puts).once.
            with(:info, "Final status for job 'p1/j1': errored")
          expect(logger).to have_received(:log_and_puts).once.
            with(:info, "Failure ignored for this job.")
        end
      end

      context "when the failure is not ignored" do
        it "exits the program with an exit code 1" do
          logger = build.logger
          allow(logger).to receive(:log_and_puts)
          allow(pipeline).to receive(:pause)
          allow(job).to receive(:watch)

          expect{ build.handle_result(false) }.to raise_error(SystemExit)

          expect(logger).to have_received(:log_and_puts).once.
            with(:info, "Final status for job 'p1/j1': errored")
        end
      end
    end

    context "when no failure happened" do
      let(:status) { "succeeded" }
      let(:build) { described_class.new(job: job, status: status) }

      it "just logs the final status" do
        logger = build.logger
        allow(logger).to receive(:log_and_puts)
        allow(pipeline).to receive(:pause)

        expect{ build.handle_result(true) }.to_not raise_error(SystemExit)

        expect(logger).to have_received(:log_and_puts).once.
          with(:info, "Final status for job 'p1/j1': succeeded")
      end
    end
  end
end
