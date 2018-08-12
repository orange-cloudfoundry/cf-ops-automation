require 'spec_helper'
require 'concerns/coa_concourse/build'

describe CoaConcourse::Build do
  let(:fly) { double("CoaConcourse::FlyClient") }

  describe '#watch_job' do
    let(:full_job_name) { "p1/j1" }

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

  describe '#handle_result'
end

