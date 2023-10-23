require 'pathname'

require_relative '../constants'

module Coa
  module IntegrationTests
    # This class contains useful constant for the integration tests, such as the
    # list of pipelines to their with their jobs and those latter's
    # configuration.
    module Constants
      include Coa::Constants

      FLY_TARGET = "bucc".freeze
      PIPELINES = {
        "bootstrap-all-init-pipelines" => {
          "team" => "main",
          "jobs" => {
            "bootstrap-pipelines" => { "trigger" => true },
            "reload-this-pipeline-from-git" => { "trigger" => true },
            "create-teams" => {},
            "bootstrap-control-plane" => {}
          }
        },
        "shared-control-plane-generated" => {
          "team" => "main",
          "jobs" => {
            "update-pipeline-hello-world-root-depls" => {},
            "update-pipeline-shared" => {},
            "on-git-commit" => {},
            "push-changes" => {},
            "save-deployed-pipelines" => {}
          }
        },
        "shared-concourse-generated" => {
          "team" => "main",
          "jobs" => {
            "deploy-concourse-pipeline-sample-pipeline" => {}
          }
        },
        "shared-kubernetes-generated" => {
          "team" => "main",
          "jobs" => {
            "deploy-k8s-sample-hello-world-root-depls" => {},
            "execute-deploy-script-hello-world-root-depls" => {}
          }
        },
        "hello-world-root-depls-cf-apps-generated" => {
          "team" => "hello-world-root-depls",
          "jobs" => {
            # "cf-push-generic-app" => {}
          }
        },
        "hello-world-root-depls-bosh-precompile-generated" => {
          "team" => "hello-world-root-depls",
          "jobs" => {
            "compile-and-export-cron" => {},
            "compile-and-export-nginx" => {},
            "compile-and-export-vault" => {},
            "upload-stemcell-to-director" => {},
            "push-boshreleases" => {},
            "init-concourse-boshrelease-and-stemcell-for-hello-world-root-depls" => {}
          }
        },
        "hello-world-root-depls-bosh-generated" => {
          "team" => "hello-world-root-depls",
          "jobs" => {
            "delete-deployments-review" => {},
            "approve-and-delete-disabled-deployments" => { "trigger" => true },
            "init-concourse-boshrelease-and-stemcell-for-hello-world-root-depls" => {},
            "cloud-config-and-runtime-config-for-hello-world-root-depls" => { "pause" => true },
            "execute-deploy-script" => {},
            "deploy-bosh-deployment-sample" => {},
            "check-terraform-consistency" => {},
            "check-terraform-is-applied" => { "ignore-failure" => true }, # As we expect an error due to terraform change not applied yet
            "approve-and-enforce-terraform-consistency" => { "trigger" => true },
            "cancel-all-bosh-tasks" => { "trigger" => true },
            "upload-stemcell-to-director" => {},
            "push-boshreleases" => {}
          }
        },
        "hello-world-root-depls-k8s-generated" => {
          "team" => "hello-world-root-depls",
          "jobs" => {
            "deploy-k8s-sample" => {},
            "execute-deploy-script" => {}
          }
        },
        "hello-world-root-depls-pipeline-sample" => {
          "team" => "main",
          "jobs" => {
            "upload-latest-vault-boshrelease-to-s3" => { "pause" => true },
            "validate-secrets-injection-value-from-coa-config" => {}
          }
        }
      }.freeze
    end
  end
end
