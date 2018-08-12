require 'spec_helper'
require 'concerns/coa_concourse/concourse_client'
require 'concerns/coa_concourse/fly_client'

describe CoaConcourse::ConcourseClient do
  let(:target) { "target" }
  let(:creds) { { "concourse_client" => "client" } }
  let(:concourse) { described_class.new(target, creds) }
  let(:fly) { instance_double("CoaConcourse::FlyClient") }

  before do
    allow(CoaConcourse::FlyClient).to receive(:new).and_return(fly)
  end

  describe '#run_and_watch_pipelines' do
    let(:pipelines) do
      {
        "p1" => {
          "j1" => { "trigger" => true }
        },
        "p2" => {
          "j1" => { "ignore-failure" => true },
          "j2" => { "pause" => true }
        }
      }
    end
    let(:build) { instance_double("CoaConcourse::Build") }

    it 'watches jobs for each pipeline' do
      allow(fly).to receive(:unpause_pipeline)
      allow(fly).to receive(:trigger_job)
      allow(fly).to receive(:pause_job)
      allow(CoaConcourse::Build).to receive(:watch_job).and_return(build)
      allow(build).to receive(:handle_result)
      allow(fly).to receive(:pause_pipeline)

      concourse.run_and_watch_pipelines(pipelines)

      expect(fly).to have_received(:unpause_pipeline).once.with("p1")
      expect(fly).to have_received(:trigger_job).once.with("p1/j1")
      expect(CoaConcourse::Build).to have_received(:watch_job).with("p1/j1", 1800, fly)
      expect(build).to have_received(:handle_result).once.with(nil)
      expect(build).to have_received(:handle_result).once.with(true)
      expect(fly).to have_received(:pause_pipeline).once.with("p1")

      expect(fly).to have_received(:pause_job).with("p2/j2")
      expect(fly).to have_received(:unpause_pipeline).once.with("p2")
      expect(CoaConcourse::Build).to have_received(:watch_job).with("p2/j1", 1800, fly)
      expect(fly).to have_received(:pause_pipeline).once.with("p2")
    end
  end
end
