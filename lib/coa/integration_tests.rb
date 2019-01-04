require 'yaml'
require 'json'
require 'tempfile'

require_relative './env_bootstrapper'
require_relative './utils/coa_logger'
require_relative './utils/command_runner'
require_relative './utils/concourse/client'

module Coa
  # This class can run a COA Integration Tests, where we test the jobs listed in
  # the PIPELINES constant variable.
  class IntegrationTests
    include Coa::Utils::CoaLogger

    ROOT = File.absolute_path(File.join(File.dirname(__FILE__), '..'))
    FLY_TARGET = "bucc".freeze
    PIPELINES = {
      "bootstrap-all-init-pipelines" => {
        "bootstrap-pipelines"        => { "trigger" => true },
        "create-teams"               => {},
        "bootstrap-control-plane"    => {},
        "bootstrap-init-pipelines"   => {},
        "bootstrap-update-pipelines" => {}
      },
      "hello-world-root-depls-update-generated" => {
        "update-pipeline-hello-world-root-depls" => {}
      },
      "control-plane" => {
        "on-git-commit"            => {},
        "load-generated-pipelines" => {},
        "push-changes"             => {}
      },
      "hello-world-root-depls-init-generated" => {
        "update-pipeline-hello-world-root-depls" => {}
      },
      "hello-world-root-depls-bosh-generated" => {
        "cloud-config-and-runtime-config-for-hello-world-root-depls" => { "pause" => true },
        "recreate-bosh-deployment-sample"                            => { "pause" => true },
        "execute-deploy-script"                                      => {},
        # see issue https://github.com/orange-cloudfoundry/cf-ops-automation/issues/220 "deploy-bosh-deployment-sample" => { "trigger" => true },
        "recreate-all"                                               => { "trigger" => true },
        "check-terraform-consistency"                                => {},
        "approve-and-enforce-terraform-consistency"                  => { "trigger" => true },
        "cancel-all-bosh-tasks"                                      => { "trigger" => true }
      },
      "hello-world-root-depls-generated" => {
        "cloud-config-and-runtime-config-for-hello-world-root-depls"         => { "pause" => true },
        "init-concourse-boshrelease-and-stemcell-for-hello-world-root-depls" => {},
        "update-pipeline-hello-world-root-depls-generated"                   => {},
        "execute-deploy-script"                                              => {},
        "deploy-bosh-deployment-sample"                                      => { "trigger" => true }
      },
      "hello-world-root-depls-concourse-generated" => {
        "deploy-concourse-pipeline-sample-pipeline" => {}
      },
      "hello-world-root-depls-pipeline-sample" => {}
    }.freeze

    attr_reader :prereqs_paths

    def initialize(prereqs_paths)
      logger.log_and_puts :debug, "prereqs paths:\n#{prereqs_paths}"
      @prereqs_paths = prereqs_paths
    end

    # This method first destroy pipelines if it can communicate with concourse
    # then it installs, if needed, bucc and then sets the pipeline "bootstrap-all-init-pipelines" and starts it
    # then it watches pipelines.
    # we destroy the pipeline only when we assume there's already a concourse running
    def run
      destroy_pipelines if prereqs["inactive_steps"].include?("deploy_transient_infra")
      bootstrap_coa_env
      watch_pipelines unless prereqs["inactive_steps"].include?("run_pipelines")
    end

    def concourse
      Coa::Utils::Concourse::Client.new(FLY_TARGET, concourse_config)
    end

    def concourse_config
      creds = concourse_prereqs || bucc.vars
      creds["target"] = creds["url"] unless creds["target"]
      creds["insecure"] = false if creds["insecure"].nil?

      Coa::Utils::Concourse::Config.new(creds)
    end

    def bucc
      prereqs['bucc'] && Coa::EnvBootstrapper::Bucc.new(prereqs['bucc'])
    end

    def concourse_prereqs
      prereqs['concourse']
    end

    def prereqs
      @prereqs ||=
        begin
          ps = prereqs_paths.inject({}) { |content, path| content.merge(YAML.load_file(path)) }
          logger.log_and_puts :info, ps.inspect
          ps
        end
    end

    private

    def destroy_pipelines
      logger.log_and_puts :info, "Destroying pipelines"
      concourse.destroy_pipelines(PIPELINES)
    end

    def bootstrap_coa_env
      logger.log_and_puts :info, "Bootstrapping COA ENV"
      Coa::EnvBootstrapper::Runner.run_from_prereqs(prereqs_paths)
    end

    def watch_pipelines
      logger.log_and_puts :info, "Run and watch pipelines"
      concourse.run_and_watch_pipelines(PIPELINES, 600)
    end
  end
end
