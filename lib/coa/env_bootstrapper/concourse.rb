require 'yaml'

require_relative './base'
require_relative '../utils/concourse/concourse'
require_relative '../utils/concourse/config'

module Coa
  module EnvBootstrapper
    # This class manages interactions between the COA Boostrapper and Concourse
    class Concourse < Coa::EnvBootstrapper::Base
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def run_pipelines(inactive_steps:, prereqs_pipeline_vars:, bosh_config:, git_server_ip:)
        logger.log_and_puts :debug, 'Running pipeline jobs'
        set_pipelines(prereqs_pipeline_vars, bosh_config, git_server_ip) unless inactive_steps.include?("set_pipelines")

        return if inactive_steps.include?("run_pipelines")
        start_pipeline
      end

      def set_pipelines(prereqs_pipeline_vars, bosh_config, git_server_ip)
        tempfile = create_pipeline_vars_tempfile(prereqs_pipeline_vars, bosh_config, git_server_ip)
        options  = set_pipelines_options(tempfile, git_server_ip)
        client.set_pipeline(name: "bootstrap-all-init-pipelines", options: options)
      ensure
        tempfile&.unlink
      end

      def start_pipeline
        client.unpause_pipeline(name: "bootstrap-all-init-pipelines")
      end

      def client
        @client ||= Coa::Utils::Concourse::Concourse.new(config.target, config)
      end

      private

      def set_pipelines_options(pipeline_vars_file, git_server_ip)
        "--config #{PROJECT_ROOT_DIR}/concourse/pipelines/bootstrap-all-init-pipelines.yml \
--load-vars-from #{pipeline_vars_file.path} \
--var paas-templates-uri='git://#{git_server_ip}/paas-templates' \
--var secrets-uri='git://#{git_server_ip}/secrets' \
--var cf-ops-automation-uri='git://#{git_server_ip}/cf-ops-automation' \
--var concourse-micro-depls-target='#{config.url}' \
--var concourse-micro-depls-username='#{config.username}' \
--var concourse-micro-depls-password='#{config.password}'"
      end

      def create_pipeline_vars_tempfile(prereqs_pipeline_vars, bosh_config, git_server_ip)
        pipeline_vars_file = Tempfile.new("pipeline-vars.yml")
        vars = pipeline_vars(prereqs_pipeline_vars, bosh_config, git_server_ip)
        pipeline_vars_file.write(vars)
        pipeline_vars_file.close
        pipeline_vars_file
      end

      def pipeline_vars(prereqs_pipeline_vars, bosh_config, git_server_ip)
        vars = generated_pipeline_vars(bosh_config, git_server_ip)
        prereqs_pipeline_vars.merge(vars).to_yaml
      end

      def generated_pipeline_vars(bosh_config, git_server_ip)
        {
          "bosh-target"                               => bosh_config.target,
          "bosh-username"                             => bosh_config.client,
          "bosh-password"                             => bosh_config.client_secret,
          "bosh-ca-cert"                              => bosh_config.ca_cert,
          "bosh-environment"                          => bosh_config.target,
          "secrets-uri"                               => "git://#{git_server_ip}/secrets",
          "paas-templates-uri"                        => "git://#{git_server_ip}/paas-templates",
          "cf-ops-automation-uri"                     => "git://#{git_server_ip}/cf-ops-automation",
          "concourse-hello-world-root-depls-insecure" => config.insecure,
          "concourse-hello-world-root-depls-password" => config.password,
          "concourse-hello-world-root-depls-target"   => config.url,
          "concourse-hello-world-root-depls-username" => config.username
        }
      end
    end
  end
end
