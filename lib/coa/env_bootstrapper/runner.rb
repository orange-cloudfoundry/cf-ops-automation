require 'json'
require 'tmpdir'
require 'yaml'

require_relative './base'
require_relative './bosh'
require_relative './concourse'
require_relative './env_creator_adapter'
require_relative './git'

module Coa
  module EnvBootstrapper
    # This class will create a COA env provided preprequisites yaml files, and
    # then run Concourse pipelines
    class Runner < Base
      attr_reader :env_creator_adapter, :prereqs

      def initialize(prereqs_paths)
        @prereqs = load_prereqs(prereqs_paths) || {}
        logger.log_and_puts :debug, "Running Bootstrapper with config:\n#{JSON.pretty_generate(@prereqs)}"
        @env_creator_adapter = @prereqs["bucc"] && EnvCreatorAdapter.new("bucc", @prereqs)
      end

      def self.run_from_prereqs(prereqs_paths)
        new(prereqs_paths).run
      end

      def load_prereqs(prereqs_paths)
        prereqs_paths.inject({}) do |ps, path|
          if File.exist?(path)
            ps.merge(YAML.load_file(path))
          else
            logger.log_and_puts :info, "File #{path} not found. Will be ignored."
            ps
          end
        end
      end

      def run
        env_creator_adapter.deploy_transient_infra unless env_creator_adapter.nil? || inactive_step?("deploy_transient_infra")

        prepare_bosh_environment
        prepare_git_environment
        run_pipeline_jobs unless inactive_step?("run_pipelines")
      end

      def prepare_bosh_environment
        logger.log_and_puts :debug, 'Preparing BOSH environment'
        bosh.upload_stemcell(prereqs["stemcell"])              unless inactive_step?("upload_stemcell")
        bosh.update_cloud_config(prereqs["cloud_config"])      unless inactive_step?("update_cloud_config")
        bosh.deploy_git_server(prereqs["git_server_manifest"]) unless inactive_step?("deploy_git_server")
      end

      def prepare_git_environment
        logger.log_and_puts :debug, 'Preparing git environment'

        git.push_templates_repo
        git.push_secrets_repo(concourse.config)
        git.push_cf_ops_automation
      end

      def run_pipeline_jobs
        logger.log_and_puts :debug, 'Running pipeline jobs'

        set_pipelines unless inactive_step?("set_pipelines")

        return if inactive_step?("run_pipelines")
        concourse.unpause_pipelines
        concourse.trigger_jobs
      end

      def bosh
        bosh_config_source = prereqs["bosh"] || @env_creator_adapter&.vars || {}
        Bosh.new(bosh_config_source)
      end

      def git
        Git.new(bosh, prereqs)
      end

      def concourse
        concourse_config_source = prereqs["concourse"] || @env_creator_adapter&.vars || {}
        Concourse.new(concourse_config_source)
      end

      private

      def inactive_step?(step)
        prereqs["inactive_steps"]&.include?(step)
      end

      def set_pipelines
        pipeline_vars_file = Tempfile.new("pipeline-vars.yml")
        pipeline_vars_file.write(pipeline_vars)
        pipeline_vars_file.close
        concourse.set_pipelines(pipeline_vars_file.path, bosh.git_server_ip)
      ensure
        pipeline_vars_file&.unlink
      end

      def pipeline_vars
        vars = prereqs["pipeline-vars"] || {}
        vars.merge(generated_pipeline_vars).to_yaml
      end

      def generated_pipeline_vars
        bosh_config      = bosh.config
        git_server_ip    = bosh.git_server_ip
        concourse_config = concourse.config

        {
          "bosh-target"                               => bosh_config.target,
          "bosh-username"                             => bosh_config.client,
          "bosh-password"                             => bosh_config.client_secret,
          "bosh-ca-cert"                              => bosh_config.ca_cert,
          "bosh-environment"                          => bosh_config.target,
          "secrets-uri"                               => "git://#{git_server_ip}/secrets",
          "paas-templates-uri"                        => "git://#{git_server_ip}/paas-templates",
          "cf-ops-automation-uri"                     => "git://#{git_server_ip}/cf-ops-automation",
          "concourse-hello-world-root-depls-insecure" => concourse_config.insecure,
          "concourse-hello-world-root-depls-password" => concourse_config.password,
          "concourse-hello-world-root-depls-target"   => concourse_config.url,
          "concourse-hello-world-root-depls-username" => concourse_config.username
        }
      end
    end
  end
end
