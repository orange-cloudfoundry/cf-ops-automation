require 'tmpdir'

require_relative './base'
require_relative './bosh'
require_relative './cf'
require_relative './concourse'
require_relative './env_creator'
require_relative './git'
require_relative './prereqs'

module Coa
  module EnvBootstrapper
    # This class will create a COA env provided preprequisites yaml files, and
    # then run Concourse pipelines
    class Bootstrapper < Base
      attr_reader :prereqs

      def initialize(prereqs = Coa::EnvBootstrapper::Prereqs.new)
        # raise "Argument 'prereqs' must be of class 'Coa::EnvBootstrapper::Prereqs'" unless prereqs.is_a?(Coa::EnvBootstrapper::Prereqs)
        @prereqs = prereqs
      end

      def self.new_from_prereqs_paths(prereqs_paths)
        prereqs = Coa::EnvBootstrapper::Prereqs.new_from_paths(prereqs_paths)
        logger.log_and_puts :debug, "Running Bootstrapper with config:\n#{prereqs.pretty_print}"
        new(prereqs)
      end

      def perform
        env_creator.deploy_transient_infra unless inactive_step?("deploy_transient_infra")
        bosh.prepare_environment(prereqs)
        cf.prepare_environment(prereqs)
        git.prepare_environment(concourse.config, pipeline_vars)

        return if inactive_step?("run_pipelines")
        concourse.run_pipelines(
          inactive_steps:         prereqs.inactive_steps,
          prereqs_pipeline_vars:  pipeline_vars,
          bosh_config:            bosh.config,
          git_server_ip:          bosh.git_server_ip
        )
      end

      private

      def pipeline_vars
        prereqs.pipeline_vars
      end

      def inactive_step?(step)
        prereqs.inactive_step?(step)
      end

      def env_creator
        Coa::EnvBootstrapper::EnvCreator.new(prereqs)
      end

      def bosh
        config_source = prereqs.bosh || env_creator.vars
        bosh_config = Coa::Utils::Bosh::Config.new(config_source)
        Coa::EnvBootstrapper::Bosh.new(bosh_config)
      end

      def cf
        Coa::EnvBootstrapper::Cf.new({})
      end

      def git
        Coa::EnvBootstrapper::Git.new(bosh)
      end

      def concourse
        config_source = prereqs.concourse || env_creator.vars
        config = Coa::Utils::Concourse::Config.new(config_source)
        Coa::EnvBootstrapper::Concourse.new(config)
      end
    end
  end
end
