require 'spec_helper'
require 'coa/utils/concourse/client'
require 'coa/utils/concourse/fly'

describe Coa::Utils::Concourse::Client do
  let(:target) { "target" }
  let(:creds) { { "concourse_client" => "client" } }
  let(:concourse) { described_class.new(target, creds) }
  let(:fly_client) { instance_double("Coa::Utils::Concourse::Fly") }

  before do
    allow(Coa::Utils::Concourse::Fly).to receive(:new).and_return(fly_client)
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
    let(:build) { instance_double("Coa::Utils::Concourse::Build") }

    it 'watches jobs for each pipeline' do
      allow(fly_client).to receive(:unpause_pipeline)
      allow(fly_client).to receive(:trigger_job)
      allow(fly_client).to receive(:pause_job)
      allow(Coa::Utils::Concourse::Build).to receive(:watch_job).and_return(build)
      allow(build).to receive(:handle_result)
      allow(fly_client).to receive(:pause_pipeline)

      concourse.run_and_watch_pipelines(pipelines)

      expect(fly_client).to have_received(:unpause_pipeline).once.with("p1")
      expect(fly_client).to have_received(:trigger_job).once.with("p1/j1")
      expect(Coa::Utils::Concourse::Build).to have_received(:watch_job).with("p1/j1", 1800, fly_client)
      expect(build).to have_received(:handle_result).once.with(nil)
      expect(build).to have_received(:handle_result).once.with(true)
      expect(fly_client).to have_received(:pause_pipeline).once.with("p1")

      expect(fly_client).to have_received(:pause_job).with("p2/j2")
      expect(fly_client).to have_received(:unpause_pipeline).once.with("p2")
      expect(Coa::Utils::Concourse::Build).to have_received(:watch_job).with("p2/j1", 1800, fly_client)
      expect(fly_client).to have_received(:pause_pipeline).once.with("p2")
    end
  end
end
