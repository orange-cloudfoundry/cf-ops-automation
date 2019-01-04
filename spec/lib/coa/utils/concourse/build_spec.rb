require 'spec_helper'
require 'coa/utils/concourse'

describe Coa::Utils::Concourse::Build do
  let(:fly) { double("Coa::Utils::Concourse::Fly") }

  describe '#watch_job' do
    let(:full_job_name) { "p1/j1" }
    before { allow(described_class).to receive(:sleep) }

    context "when the jobs has succeeded" do
      let(:build_response) { "34455  p1/j1  1  succeeded  2018-12-14@09:27:20+0000  n/a  17m33s+" }

      it "returns a build directly" do
        allow(fly).to receive(:get_raw_job_builds).and_return(build_response)

        build = described_class.watch_job(full_job_name, 2, fly)

        expect(build.name).to eq("1")
        expect(build.status).to eq("succeeded")
        expect(build.full_job_name).to eq("p1/j1")

        expect(fly).to have_received(:get_raw_job_builds).with("p1/j1").once
      end
    end

    context "when the job has not succeeded" do
      let(:build_response) { "34455  p1/j1  1  started  2018-12-14@09:27:20+0000  n/a  17m33s+" }

      it "retries" do
        allow(fly).to receive(:get_raw_job_builds).and_return(build_response)

        build = described_class.watch_job(full_job_name, 2, fly)

        expect(build.name).to eq("1")
        expect(build.status).to eq("started")
        expect(build.full_job_name).to eq("p1/j1")

        expect(fly).to have_received(:get_raw_job_builds).with("p1/j1").twice
      end
    end
  end

  describe '#handle_result' do
    let(:build) { described_class.new(name: 1, status: status, full_job_name: "p1/j1") }

    context "when a failure happened" do
      let(:status) { "errored" }

      context "when the failure is ignored"  do
        it "just logs the final status" do
          logger = build.logger
          allow(logger).to receive(:log_and_puts)

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

          expect{ build.handle_result(false) }.to raise_error(SystemExit)

          expect(logger).to have_received(:log_and_puts).once.
            with(:info, "Final status for job 'p1/j1': errored")
        end
      end
    end

    context "when no failure happened" do
      let(:status) { "succeeded" }

      it "just logs the final status" do
        logger = build.logger
        allow(logger).to receive(:log_and_puts)

        build.handle_result(true)

        expect(logger).to have_received(:log_and_puts).once.
          with(:info, "Final status for job 'p1/j1': succeeded")
      end
    end
  end
end
