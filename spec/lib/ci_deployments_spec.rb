require 'spec_helper'
require 'ci_deployment'

describe CiDeployment do
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

  describe '#overview' do
    let(:root_deployment_name) { "root-deployment-name" }
    let(:fixture_path) { File.dirname(__FILE__) + "/fixtures/" }
    let(:path) { File.join(fixture_path, root_deployment_name, '/*') }
    let(:ci_deployments) { described_class.new(path) }

    it 'generate a hash containing the CI pipelines' do
      expect(ci_deployments.overview).to eq(ci_deployments_overview)
    end
  end

  describe '.teams' do
    subject(:teams) { described_class.teams(overview) }

    context 'when teams are defined' do
      let(:overview) do
        {
          "root-deployment-1" => {
            "target_name" => "rspec-fixture-target",
            "pipelines" => {
              "bosh-generated" => {
                "vars_files" => ["bosh/root-deployment.yml"],
                "team" => 'team-bosh'
              },
              "bosh-cf-apps-generated" => {
                "vars_files" => ["bosh/root-deployment.yml"],
                "config_file" => "concourse/pipelines/bosh-cf-apps-generated.yml",
                "team" => 'team-cf-apps'
              }
            }
          },
          "root-deployment-2" => {
            "target_name" => "rspec-fixture-target",
            "pipelines" => {
              "cf_apps-generated" => {
                "vars_files" => ["cf_apps/root-deployment.yml"],
                "config_file" => "concourse/pipelines/cf_apps-generated.yml",
                "team" => 'team-rd2'
              },
              "cf_apps-cf-apps-generated" => {
                "vars_files" => ["cf_apps/root-deployment.yml"],
                "config_file" => "concourse/pipelines/cf_apps-cf-apps-generated.yml",
                "team" => 'team-rd2'
              }
            }
          }
        }
      end

      it 'returns all defined teams' do
        expect(teams).to eq(%w[team-bosh team-cf-apps team-rd2])
      end
    end

    context 'when no teams are defined' do
      let(:overview) { ci_deployments_overview }

      it 'returns all defined teams' do
        expect(teams).to be_empty
      end
    end

    context 'when overview is empty' do
      let(:overview) { {} }

      it 'returns only main team' do
        expect(teams).to be_empty
      end
    end
  end

  describe '.team'
end
