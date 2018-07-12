require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../../../concourse/tasks/bosh_cancel_all_tasks/bosh_tasks_canceller.rb'
require_relative '../task_spec_helper'

describe 'bosh_cancel_all_tasks task' do
  let(:cancel_all_tasks) do
    stdout_str, stderr_str, status = Open3.capture3(env, 'concourse/tasks/bosh_cancel_all_tasks/run.rb')
    { stdout: stdout_str, stderr: stderr_str, status: status }
  end

  context 'when env vars are missing' do
    let(:env) { { "BOSH_ENVIRONMENT" => nil } }
    it "exits with status 1 and write error in log" do
      expect(cancel_all_tasks[:status].exitstatus).to eq 1
    end
  end

  context 'Pre-requisite' do
    let(:task) { YAML.load_file 'concourse/tasks/bosh_cancel_all_tasks/task.yml' }

    it 'uses ruby image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match(TaskSpecHelper.bosh_cli_v2_image)
    end

    it 'uses a managed ruby image version' do
      docker_image_tag_used = task['image_resource']['source']['tag'].to_s
      expect(docker_image_tag_used).to match(TaskSpecHelper.bosh_cli_v2_image_version)
    end
  end
end

