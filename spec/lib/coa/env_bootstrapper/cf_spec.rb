require 'yaml'
require 'spec_helper'
require 'coa/env_bootstrapper'
require 'coa/env_bootstrapper/base'
require 'coa/env_bootstrapper/cf'

describe Coa::EnvBootstrapper::Cf do
  let(:empty_config) { {} }
  let(:cf) { described_class.new(empty_config) }

  describe '#prepare_environment' do
    let(:cf_prereqs) { { a_key: 'value' } }
    let(:prereqs) do
      Coa::EnvBootstrapper::Prereqs.new({ 'cf' => cf_prereqs })
    end

    context 'when ' do
      it 'creates all pre-requisite to be able to deploy an application to CF' do
        allow(cf).to receive(:generate_activation_files).with(cf_prereqs)

        cf.prepare_environment(prereqs)

        expect(cf).to have_received(:generate_activation_files).with(cf_prereqs)
      end
    end
  end

  describe '#generate_activation_files' do
    let(:app_name) { "generic-app" }
    let(:cf_api_url) { "example.com" }
    let(:cf_username) { "xxx" }
    let(:cf_password) { "3586.23" }
    let(:cf_org) { "cf-org" }
    let(:cf_space) { "cf-space" }
    let(:cf_config) do
      {
        "api-url" => cf_api_url,
        "username" => cf_username,
        "password" => cf_password,
        "org" => cf_org,
        "space" => cf_space
      }
    end

    context 'when an application need to be deployed on cloudfoundry' do
      let(:file) { Tempfile.new }
      let(:expected_filename) { "#{Coa::EnvBootstrapper::Cf::CF_APPLICATIONS_PATH}/#{app_name}/#{Coa::EnvBootstrapper::Cf::CF_APPLICATION_ACTIVATION_FILENAME}" }
      let(:expected_activation_file_content) { { 'cf-app' => { app_name => { 'cf_api_url' => cf_api_url, 'cf_username' => cf_username, 'cf_password' => cf_password, 'cf_organization' => cf_org, 'cf_space' => cf_space } } }.to_yaml }

      it "generates an appropriate activation file" do
        allow(File).to receive(:open).with(expected_filename, "w").and_return(file)
        allow(file).to receive(:write).with(expected_activation_file_content)

        cf.generate_activation_files(cf_config)

        expect(File).to have_received(:open).with(expected_filename, "w")
        expect(file).to have_received(:write).with(expected_activation_file_content)
      end
    end
  end
end
