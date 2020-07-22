require 'spec_helper'
require 'tmpdir'
require 'yaml'
require 'csv'
require_relative '../../../concourse/tasks/repackage_boshreleases_fallback/repackage_releases_fallback'
require_relative '../task_spec_helper'

describe 'repackage_releases_fallback task' do
  context 'when executed on concourse' do
    let(:namespaces_filename) { File.join(@repackaged_releases_fallback_dir, 'boshreleases-namespaces.csv') }
    let(:namespaces) { CSV.read(namespaces_filename) }
    let(:expected_namespaces) { [%w[dummy-nats-33 cloudfoundry], %w[minio-2020-06-18T02-23-35Z minio], %w[shield-addon-bbr-0.2.1 shieldproject]] }
    let(:fallback_fixes_filename) { File.join(@repackaged_releases_fallback_dir, 'fallback-fixes.yml') }
    let(:fallback_errors_filename) { File.join(@repackaged_releases_fallback_dir, 'fallback-errors.yml') }
    let(:fallback_fixes) { YAML.load_file(fallback_fixes_filename) }
    let(:repackaged_tgz) { Dir[File.join(@repackaged_releases_fallback_dir, '*.tgz')].map { |path| File.basename(path) }.sort }
    let(:expected_repackaged_tgz) { %w[dummy-nats-33.tgz shield-addon-bbr-0.2.1.tgz minio-2020-06-18T02-23-35Z.tgz].sort }

    before(:context) do
      @repackaged_releases_fallback_dir = Dir.mktmpdir
      @fly_error = ""
      fly_cli_environment = {
      }

      @output = execute('-c concourse/tasks/repackage_boshreleases_fallback/task.yml ' \
        '-i cf-ops-automation=. ' \
        "-i repackaged-releases=#{File.join(File.dirname(__FILE__), 'repackaged-releases-sample')} " \
        "-o repackaged-releases-fallback=#{@repackaged_releases_fallback_dir} ",
                        fly_cli_environment)
    rescue FlyExecuteError => e
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
    end

    after(:context) do
      FileUtils.rm_rf @repackaged_releases_fallback_dir if File.exist?(@repackaged_releases_fallback_dir)
    end

    it 'has all tgz available' do
      expect(repackaged_tgz).to match(expected_repackaged_tgz)
    end

    it 'does not generates an error log file' do
      expect(File).not_to exist(fallback_errors_filename)
    end

    it 'generates a fix log file' do
      expect(File).to exist(fallback_fixes_filename)
    end

    it 'add required info to namespace file' do
      expect(namespaces).to match(expected_namespaces)
    end

    it 'exits without errors as it should be check by another task' do
      expect(@fly_status).to be_nil
    end

    it 'does not generate fly error' do
      expect(@fly_error).to eq("")
    end
  end

  context 'when pre-requisites are valid' do
    let(:task) { YAML.load_file 'concourse/tasks/repackage_boshreleases_fallback/task.yml' }

    it 'uses ruby image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match(TaskSpecHelper.bosh_cli_v2_image)
    end

    it 'uses a managed ruby image version' do
      docker_image_tag_used = task['image_resource']['source']['tag'].to_s
      expect(docker_image_tag_used).to match(TaskSpecHelper.bosh_cli_v2_image_version)
    end

    it 'has inputs' do
      expected_inputs = [{ 'name' => 'cf-ops-automation' }, { 'name' => 'repackaged-releases' }]
      expect(task['inputs']).to eq(expected_inputs)
    end

    it 'has outputs' do
      expected_outputs = [{ 'name' => 'repackaged-releases-fallback' }]
      expect(task['outputs']).to eq(expected_outputs)
    end

    it 'has params' do
      expected_params = { "GIT_USER_EMAIL" => "codex.clara-cloud-ops@orange.com",
                          "GIT_USER_NAME" => "Orange Cloud Foundry SKC CI Server" }
      expect(task['params']).to eq(expected_params)
    end
  end
end
