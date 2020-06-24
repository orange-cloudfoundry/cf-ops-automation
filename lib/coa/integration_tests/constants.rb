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
            "bootstrap-pipelines"            => { "trigger" => true },
            "reload-this-pipeline-from-git"  => { "trigger" => true },
            "create-teams"                   => {},
            "bootstrap-control-plane"        => {},
            "bootstrap-update-pipelines"     => {}
          }
        },
        "hello-world-root-depls-update-generated" => {
          "team" => "main",
          "jobs" => {
            "update-pipeline-hello-world-root-depls" => {}
          }
        },
        "control-plane" => {
          "team" => "main",
          "jobs" => {
            "on-git-commit"            => {},
            "load-generated-pipelines" => {},
            "push-changes"             => {},
            "save-deployed-pipelines"  => {}
          }
        },
        "hello-world-root-depls-cf-apps-generated" => {
          "team" => "main",
          "jobs" => {
            "cf-push-generic-app" => {}
          }
        },
        "hello-world-root-depls-bosh-precompile-generated" => {
            "team" => "main",
            "jobs" => {
                "hello-world-root-depls-release-precompile-deployment" => {},
                "compile-and-export-ntp" => {},
                "compile-and-export-nginx" => {},
                "compile-and-export-vault" => {},
                "init-concourse-boshrelease-and-stemcell-for-hello-world-root-depls" => {},
                "delete-hello-world-root-depls-release-precompile-deployment" => {}
            }
        },
        "hello-world-root-depls-bosh-generated" => {
          "team" => "main",
          "jobs" => {
            "delete-deployments-review"                                          => {},
            "approve-and-delete-disabled-deployments"                            => { "trigger" => true },
            "init-concourse-boshrelease-and-stemcell-for-hello-world-root-depls" => {},
            "cloud-config-and-runtime-config-for-hello-world-root-depls"         => { "pause" => true },
            "execute-deploy-script"                                              => {},
            "deploy-bosh-deployment-sample"                                      => {},
            "check-terraform-consistency"                                        => {},
            "approve-and-enforce-terraform-consistency"                          => { "trigger" => true },
            "recreate-all"                                                       => { "trigger" => true },
            "recreate-bosh-deployment-sample"                                    => {},
            "cancel-all-bosh-tasks"                                              => { "trigger" => true },
            "push-stemcell"                                                      => {},
            "push-boshreleases"                                                  => {}
          }
        },
        "hello-world-root-depls-concourse-generated" => {
          "team" => "main",
          "jobs" => {
            "deploy-concourse-pipeline-sample-pipeline" => {}
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
