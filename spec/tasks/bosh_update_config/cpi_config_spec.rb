require 'spec_helper'
require 'yaml'
require 'tmpdir'
require_relative 'test_config_generator'

describe 'bosh_update_CPI_config task' do
  context 'when no bosh is available' do

    before(:context) do
      @test_config_generator = TestConfigGenerator.new
      @secrets = Dir.mktmpdir

      fly_cli_environment = {
        'BOSH_TARGET' => 'https://dummy-bosh',
        'BOSH_CLIENT' => 'aUser',
        'BOSH_CLIENT_SECRET' => 'aPassword',
        'BOSH_CA_CERT' => 'secrets/shared/certs/internal_paas-ca/server-ca.crt',
        'CONFIG_TYPE' => 'cpi'
      }

      @output = execute('-c concourse/tasks/bosh_update_config/task.yml ' \
        '-i scripts-resource=. ' \
        "-i secrets=#{@secrets} " \
        "-i config-manifest=#{@test_config_generator.config_manifest_path} ", \
        fly_cli_environment )
    rescue FlyExecuteError => e
      puts "OUTPUT: #{e.out}"
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
    end

    after(:context) do
      @test_config_generator.cleanup
      FileUtils.rm_rf @secrets if File.exist?(@secrets)
    end

    it 'tries to login' do
      expect(@output).to include('targeting https://dummy-bosh')
    end

    it 'selects only cpi operators sorted in alphabetical order' do
      expect(@output).to include('Operators detected: < -o ./config-manifest/01-my-custom-cpi-operators.yml -o ./config-manifest/02-my-custom-cpi-operators.yml>')
    end

    it 'selects only cpi vars' do
      expect(@output).to include('Vars files detected: < -l ./config-manifest/my-custom-cpi-vars.yml>')
    end

    it 'displays an error message' do
      expect(@output).to include("no address for dummy-bosh")
    end

    it 'returns no message on stderr' do
      expect(@fly_error).to eq('')
    end

    it 'returns with exit status 1' do
      expect(@fly_status.exitstatus).to eq(1)
    end
  end

  context 'when no config file detected' do

    before(:context) do
      @test_config_generator = TestConfigGenerator.new
      @secrets = Dir.mktmpdir
      @deployed_config = Dir.mktmpdir

      fly_cli_environment = {
          'BOSH_TARGET' => 'https://dummy-bosh',
          'BOSH_CLIENT' => 'aUser',
          'BOSH_CLIENT_SECRET' => 'aPassword',
          'BOSH_CA_CERT' => 'secrets/shared/certs/internal_paas-ca/server-ca.crt',
          'CONFIG_TYPE' => 'xxx'
      }

      @output = execute('-c concourse/tasks/bosh_update_config/task.yml ' \
        '-i scripts-resource=. ' \
        "-i secrets=#{@secrets} " \
        "-o deployed-config=#{@deployed_config} " \
        "-i config-manifest=#{@test_config_generator.config_manifest_path} ", \
        fly_cli_environment )
    rescue FlyExecuteError => e
      puts "OUTPUT: #{e.out}"
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
    end

    after(:context) do
      @test_config_generator.cleanup
      FileUtils.rm_rf @secrets if File.exist?(@secrets)
      FileUtils.rm_rf @deployed_config if File.exist?(@deployed_config)
    end

    it 'generates an warning message' do
      file = File.read(File.join(@deployed_config, 'xxx-config.yml'))
      expect(file).to include('message: "WARNING - No xxx-config.yml detected"')
    end
  end

  context 'Pre-requisite' do
    let(:task) { YAML.load_file 'concourse/tasks/bosh_update_config/task.yml' }

    it 'uses alphagov bosh-cli-v2 image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match('orangecloudfoundry/bosh-cli-v2')
    end
  end
end
