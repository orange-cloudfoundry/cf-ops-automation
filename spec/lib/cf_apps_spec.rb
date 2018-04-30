require 'rspec'
require 'yaml'
require 'fileutils'
require_relative '../../lib/cf_apps'

describe CfApps do

  describe 'enable-cf-app.yml format validation' do
    it 'can have multiple applications'
    it 'root elem name is cf-app'
  end

  describe '#overview' do
    let(:fixture_path) { File.dirname(__FILE__) + "/fixtures/" }
    let(:root_deployment_name) { "root-deployment-name" }
    let(:base_path) { File.join(fixture_path + root_deployment_name + '/*') }
    let(:cf_apps) { CfApps.new(base_path, root_deployment_name) }

    let(:cf_apps_response) do
      {
        "rspec-fixture-app" => {
          "foo" => "bar", "base-dir" => "#{root_deployment_name}/cf_apps"
        },
        "rspec-fixture-app2" => {
          "foa" => "baa", "base-dir" => "#{root_deployment_name}/cf_apps"
        }
      }
    end

    it 'get all enable-cf-app.yml into a hash' do
      expect(cf_apps.overview).to eq(cf_apps_response)
    end

    it 'add a base-dir for each file found'

    it 'application name are uniq across all enable-cf-app.yml'
  end

end
