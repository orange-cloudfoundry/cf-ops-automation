require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../../../concourse/tasks/repackage_boshreleases/repackage_releases'
require_relative '../task_spec_helper'

describe 'repackage_releases task' do
  context 'when executed on concourse' do
    before(:context) do
      @logs_dir = Dir.mktmpdir
      @repackaged_releases_dir = Dir.mktmpdir
      @fly_error = ""
      fly_cli_environment = {
        'ROOT_DEPLOYMENT_NAME' => 'root-deployment-depls',
        'BOSH_TARGET' => 'https://dummy-bosh',
        'BOSH_CLIENT' => 'aUser',
        'BOSH_CLIENT_SECRET' => 'aPassword',
        'BOSH_CA_CERT' => 'secrets/shared/certs/internal_paas-ca/server-ca.crt'
      }

      @output = execute('-c concourse/tasks/repackage_boshreleases/task.yml ' \
        '-i cf-ops-automation=. ' \
        "-i templates-resource=#{File.join(File.dirname(__FILE__), 'templates_repo')} " \
        "-o repackaged-releases=#{@repackaged_releases_dir} " \
        "-o logs-dir=#{@logs_dir} ",
                        fly_cli_environment)
    rescue FlyExecuteError => e
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
    end

    after(:context) do
      FileUtils.rm_rf @logs_dir if File.exist?(@logs_dir)
      FileUtils.rm_rf @repackaged_releases_dir if File.exist?(@repackaged_releases_dir)
    end

    it 'displays an error message' do
      expect(@output).to include("no address for dummy-bosh")
    end

    xit 'generates an error log file' do
      puts
      expect(File).to exist(File.join(@logs_dir, 'error.log'))
    end

    it 'returns with exit status 1' do
      expect(@fly_status.exitstatus).to eq(1)
    end

    it 'does not generate fly error' do
      expect(@fly_error).to eq("")
    end
  end

  context 'when pre-requisites are valid' do
    let(:task) { YAML.load_file 'concourse/tasks/repackage_boshreleases/task.yml' }

    it 'uses ruby image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match(TaskSpecHelper.bosh_cli_v2_image)
    end

    it 'uses a managed ruby image version' do
      docker_image_tag_used = task['image_resource']['source']['tag'].to_s
      expect(docker_image_tag_used).to match(TaskSpecHelper.bosh_cli_v2_image_version)
    end

    it 'has inputs' do
      expected_inputs = [{ 'name' => 'cf-ops-automation' }, { 'name' => 'templates-resource' }, { "name" => "secrets", "optional" => true }, {"name"=>"missing-s3-boshreleases", "optional"=>true}]
      expect(task['inputs']).to eq(expected_inputs)
    end

    it 'has outputs' do
      expected_outputs = [{ 'name' => 'repackaged-releases' }, { 'name' => 'logs-dir' }]
      expect(task['outputs']).to eq(expected_outputs)
    end

    it 'has params' do
      expected_params = { "GIT_USER_EMAIL" => "codex.clara-cloud-ops@orange.com",
                          "GIT_USER_NAME" => "Orange Cloud Foundry SKC CI Server",
                          "BOSH_CA_CERT" => nil,
                          "BOSH_CLIENT" => nil,
                          "BOSH_CLIENT_SECRET" => nil,
                          "BOSH_TARGET" => nil,
                          "ROOT_DEPLOYMENT_NAME" => nil }
      expect(task['params']).to eq(expected_params)
    end

  end
end
