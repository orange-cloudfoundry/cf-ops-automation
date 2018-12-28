require_relative '../concerns/coa_concourse/concourse_client'

module CoaEnvBootstrapper
  # This class manages interactions with Concourse during the COA env bootstrap
  class Concourse < Base
    CONCOURSE_TARGET = "concourse-target".freeze

    attr_reader :config_source

    def initialize(config_source)
      @config_source = config_source
    end

    def set_pipelines(pipeline_vars_path, git_server_ip)
      options = "--config #{PROJECT_ROOT_DIR}/concourse/pipelines/bootstrap-all-init-pipelines.yml \
--load-vars-from #{pipeline_vars_path} \
--var paas-templates-uri='git://#{git_server_ip}/paas-templates' \
--var secrets-uri='git://#{git_server_ip}/secrets' \
--var cf-ops-automation-uri='git://#{git_server_ip}/cf-ops-automation' \
--var concourse-micro-depls-target='#{config['url']}' \
--var concourse-micro-depls-username='#{config['username']}' \
--var concourse-micro-depls-password='#{config['password']}'"

      concourse_client.set_pipeline("bootstrap-all-init-pipelines", options)
    end

    def unpause_pipelines
      concourse_client.unpause_pipeline("bootstrap-all-init-pipelines")
    end

    def trigger_jobs
      concourse_client.trigger_job("bootstrap-all-init-pipelines/bootstrap-init-pipelines")
    end

    def config
      insecure = config_source["concourse_insecure"].nil? ? "true" : config_source["concourse_insecure"].to_s
      {
        "target"   => config_source["concourse_target"] || CONCOURSE_TARGET,
        "url"      => config_source["concourse_url"],
        "username" => config_source["concourse_username"],
        "password" => config_source["concourse_password"],
        "insecure" => insecure,
        "ca_cert"  => config_source["concourse_ca_cert"]
      }
    end

    def concourse_client
      @concourse_client ||= CoaConcourse::ConcourseClient.new(CONCOURSE_TARGET, config)
    end
  end
end
