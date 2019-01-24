require 'yaml'

require_relative './constants'
require_relative '../env_bootstrapper'
require_relative '../utils/coa_logger'
require_relative '../utils/command_runner'
require_relative '../utils/concourse/concourse'

module Coa
  module IntegrationTests
    # This class can run a COA integration test, where we test the jobs listed
    # in the PIPELINES constant variable.
    class Runner
      include Coa::IntegrationTests::Constants
      include Coa::Utils::CoaLogger

      attr_reader :prereqs

      def initialize(prereqs_paths)
        @prereqs = Coa::EnvBootstrapper::Prereqs.new_from_paths(prereqs_paths)
      end

      # This method first destroy pipelines if it can communicate with concourse
      # then it installs, if needed, bucc and then sets the pipeline "bootstrap-all-init-pipelines" and starts it
      # then it watches pipelines.
      def start
        logger.info "Starting Integration Tests with prereqs:\n#{prereqs}"

        destroy_pipelines unless prereqs.inactive_step?("destroy_pipelines")
        bootstrap_coa_env
        watch_pipelines unless prereqs.inactive_step?("run_pipelines")
      end

      def env_bootstrapper
        Coa::EnvBootstrapper::Bootstrapper.new(prereqs)
      end

      def concourse
        Coa::Utils::Concourse::Concourse.new(FLY_TARGET, concourse_config)
      end

      def concourse_config
        creds = prereqs.concourse || env_creator.vars
        creds["target"] = creds["url"] unless creds["target"]
        creds["insecure"] = false if creds["insecure"].nil?

        Coa::Utils::Concourse::Config.new(creds)
      end

      def env_creator
        Coa::EnvBootstrapper::EnvCreator.new(prereqs)
      end

      def destroy_pipelines
        logger.log_and_puts :info, "Destroying pipelines"
        concourse.destroy_pipelines(PIPELINES)
      end

      def bootstrap_coa_env
        logger.log_and_puts :info, "Bootstrapping COA ENV"
        env_bootstrapper.perform
      end

      def watch_pipelines
        logger.log_and_puts :info, "Run and watch pipelines"
        concourse.unpause_and_watch_pipelines(PIPELINES)
      end
    end
  end
end
