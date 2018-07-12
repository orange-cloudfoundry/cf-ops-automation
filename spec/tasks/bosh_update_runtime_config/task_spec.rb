require 'spec_helper'
require 'yaml'
require 'tmpdir'

describe 'bosh_update_runtime_config task' do
  context 'when no bosh is available' do
    before(:context) do
      @config_manifest = Dir.mktmpdir
      @secrets = Dir.mktmpdir

      FileUtils.touch(File.join(@config_manifest, 'my-custom-config-vars.yml'))
      FileUtils.touch(File.join(@config_manifest, 'my-custom-config-operators.yml'))
      FileUtils.touch(File.join(@config_manifest, 'my-custom-runtime-vars.yml'))
      FileUtils.touch(File.join(@config_manifest, 'my-custom-runtime-operators.yml'))

      @output = execute('-c concourse/tasks/bosh_update_runtime_config.yml ' \
        '-i scripts-resource=. ' \
        "-i secrets=#{@secrets} " \
        "-i config-manifest=#{@config_manifest} ", \
        'BOSH_TARGET' => 'https://dummy-bosh',
        'BOSH_CLIENT' => 'aUser',
        'BOSH_CLIENT_SECRET' => 'aPassword',
        'BOSH_CA_CERT' => 'secrets/dummy' )
    end

    after(:context) do
      FileUtils.rm_rf @config_manifest if File.exist?(@config_manifest)
      FileUtils.rm_rf @secrets if File.exist?(@secrets)
    end

    it 'tries to login' do
      expect(@output).to include('targeting https://dummy-bosh')
    end

    it 'displays an error message' do
      expect(@output).to include("no address for dummy-bosh")
    end

    it 'selects only runtime operators' do
      expect(@output).to include('Operators detected: <-o ./config-manifest/my-custom-runtime-operators.yml >')
    end

    it 'selects only runtime vars' do
      expect(@output).to include('Vars files detected: <-l ./config-manifest/my-custom-runtime-vars.yml >')
    end
  end

  context 'Pre-requisite' do
    let(:task) { YAML.load_file 'concourse/tasks/bosh_update_runtime_config.yml' }

    it 'uses alphagov bosh-cli-v2 image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match('governmentpaas/bosh-cli-v2')
    end
  end
end
