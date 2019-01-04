require_relative './base'
require_relative '../utils/concourse/client'
require_relative '../utils/concourse/config'

module Coa
  module EnvBootstrapper
    # This class manages interactions with Concourse during the COA env bootstrap
    class Concourse < Coa::EnvBootstrapper::Base
      attr_reader :config_source

      def initialize(config_source)
        @config_source = config_source
      end

      def set_pipelines(pipeline_vars_path, git_server_ip)
        options = set_pipelines_options(pipeline_vars_path, git_server_ip)
        client.set_pipeline("bootstrap-all-init-pipelines", options)
      end

      def unpause_pipelines
        client.unpause_pipeline("bootstrap-all-init-pipelines")
      end

      def trigger_jobs
        client.trigger_job("bootstrap-all-init-pipelines/bootstrap-init-pipelines")
      end

      def config
        Coa::Utils::Concourse::Config.new(config_source)
      end

      def client
        @client ||= Coa::Utils::Concourse::Client.new(config.target, config)
      end

      private

      def set_pipelines_options(pipeline_vars_path, git_server_ip)
        "--config #{PROJECT_ROOT_DIR}/concourse/pipelines/bootstrap-all-init-pipelines.yml \
--load-vars-from #{pipeline_vars_path} \
--var paas-templates-uri='git://#{git_server_ip}/paas-templates' \
--var secrets-uri='git://#{git_server_ip}/secrets' \
--var cf-ops-automation-uri='git://#{git_server_ip}/cf-ops-automation' \
--var concourse-micro-depls-target='#{config.url}' \
--var concourse-micro-depls-username='#{config.username}' \
--var concourse-micro-depls-password='#{config.password}'"
      end
    end
  end
end
