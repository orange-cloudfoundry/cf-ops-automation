require 'yaml'
require 'spec_helper'
require 'coa/env_bootstrapper'
# require 'coa/env_bootstrapper/base'
# require 'coa/env_bootstrapper/credhub'

describe Coa::EnvBootstrapper::Credhub do
  let(:credhub_prereqs) { { 'server' => 'my-server', 'client' => 'my-client-id', 'secret' => 'my-secret' } }
  let(:prereqs) do
    Coa::EnvBootstrapper::Prereqs.new({ 'credhub' => credhub_prereqs })
  end
  let(:credhub) { described_class.new(prereqs) }

  describe '#new' do
    context 'when config is empty' do
      let(:prereqs) do
        Coa::EnvBootstrapper::Prereqs.new({})
      end

      it 'raises an error' do
        expect{credhub}.to raise_error(Coa::EnvBootstrapper::NoActiveStepConfigError, "No 'credhub.server' config provided in the prerequisites but step 'transform_config_into_credentials' active.")
      end
    end

    context 'when config contains only credhub server' do
      let(:prereqs) do
        Coa::EnvBootstrapper::Prereqs.new({ 'credhub' => { 'server' => 'my-server'} })
      end

      it 'raises an error' do
        expect{credhub}.to raise_error(Coa::EnvBootstrapper::NoActiveStepConfigError, "No 'credhub.client' config provided in the prerequisites but step 'transform_config_into_credentials' active.")
      end
    end

    context 'when config contains credhub server and client id' do
      let(:prereqs) do
        Coa::EnvBootstrapper::Prereqs.new({ 'credhub' => { 'server' => 'my-server', 'client' => 'my-client-id' } })
      end

      it 'raises an error' do
        expect{credhub}.to raise_error(Coa::EnvBootstrapper::NoActiveStepConfigError, "No 'credhub.secret' config provided in the prerequisites but step 'transform_config_into_credentials' active.")
      end
    end
  end

  describe '#prepare_environment' do
    let(:file) { Tempfile.new }
    let(:expected_credentials_file_content) { { "credhub-client" => "my-client-id", "credhub-secret" => "my-secret", "credhub-server" => "my-server" } }

    before do
      @coa_config_dir =  Dir.mktmpdir unless @coa_config_dir
    end

    context 'when credhub setup is successfull' do
      it 'creates all pre-requisite to be able use credhub variables in pipelines' do
        stub_const("Coa::EnvBootstrapper::Credhub::CREDHUB_CREDENTIALS_FILENAME", file)
        credhub.prepare_environment

        expect(YAML.load_file(file)).to eq(expected_credentials_file_content)
      end

      it 'uses a valid generated filename' do
        expect(Coa::EnvBootstrapper::Credhub::CREDHUB_CREDENTIALS_FILENAME).not_to include('pipeline')
        expect(Coa::EnvBootstrapper::Credhub::CREDHUB_CREDENTIALS_FILENAME).not_to include('generated')
      end
    end
  end
end
