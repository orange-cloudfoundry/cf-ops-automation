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
            "cancel-all-bosh-tasks"                                              => { "trigger" => true }
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
        },
        "hello-world-root-depls-s3-br-upload-generated" => {
          "team" => "upload",
          "jobs" => {
            "init-concourse-boshrelease-for-hello-world-root-depls" => { "trigger" => true },
            "upload-current-ntp"                                    => { "pause" => true },
            "upload-current-nginx"                                  => { "pause" => true },
            "upload-current-vault"                                  => { "pause" => true }
          }
        },
        "hello-world-root-depls-s3-stemcell-upload-generated" => {
          "team" => "upload",
          "jobs" => {
            "init-concourse-stemcells-for-hello-world-root-depls" => { "trigger" => true },
            "upload-current-bosh-openstack-kvm-ubuntu-xenial-go_agent" => { "pause" => true }
          }
        }
      }.freeze
    end
  end
end
