require 'spec_helper'
require 'ci_deployment'

describe CiDeployment do
  describe '#overview' do
    let(:root_deployment_name) { "root-deployment-name" }
    let(:fixture_path) { File.dirname(__FILE__) + "/fixtures/" }
    let(:path) { File.join(fixture_path, root_deployment_name, '/*') }
    let(:ci_deployments) { described_class.new(path) }

    let(:ci_deployments_overview) do
      {
        "bosh" => {
          "target_name" => "rspec-fixture-target",
          "pipelines" => {
            "bosh-generated" => {
              "vars_files" => ["bosh/root-deployment.yml"],
              "config_file" => "concourse/pipelines/bosh-generated.yml"
            },
            "bosh-cf-apps-generated" => {
              "vars_files" => ["bosh/root-deployment.yml"],
              "config_file" => "concourse/pipelines/bosh-cf-apps-generated.yml"
            }
          }
        },
        "cf_apps" => {
          "target_name" => "rspec-fixture-target",
          "pipelines" => {
            "cf_apps-generated" => {
              "vars_files" => ["cf_apps/root-deployment.yml"],
              "config_file" => "concourse/pipelines/cf_apps-generated.yml"
            },
            "cf_apps-cf-apps-generated" => {
              "vars_files" => ["cf_apps/root-deployment.yml"],
              "config_file" => "concourse/pipelines/cf_apps-cf-apps-generated.yml"
            }
          }
        }
      }
    end

    it 'generate a hash containing the CI pipelines' do
      expect(ci_deployments.overview).to eq(ci_deployments_overview)
    end
  end

  describe '.teams'
  describe '.team'
end
