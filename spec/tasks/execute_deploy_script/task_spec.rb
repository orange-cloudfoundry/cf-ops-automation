require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../task_spec_helper'

describe 'execute_deploy_script task' do

  context 'when pre-requisites are valid' do
    let(:task) { YAML.load_file 'concourse/tasks/execute_deploy_script.yml' }

    it 'uses alphagov bosh-cli-v2 image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match(TaskSpecHelper.bosh_cli_v2_image)
    end

    it 'uses a managed bosh-cli-v2 image version' do
      docker_image_tag_used = task['image_resource']['source']['tag'].to_s
      expect(docker_image_tag_used).to match(TaskSpecHelper.bosh_cli_v2_image_version)
    end
  end
end
