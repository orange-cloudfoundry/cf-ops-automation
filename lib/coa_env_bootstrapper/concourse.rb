require_relative './command_runner'
require_relative '../coa_env_bootstrapper'

module CoaEnvBootstrapper
  # Manage interactions with concourse during bootstrap
  class Concourse
    include CommandRunner

    attr_reader :ceb

    def initialize(coa_env_bootstrapper)
      @ceb = coa_env_bootstrapper
    end

    def upload_pipelines(config_dir, generated_pipeline_credentials)
      pipeline_credentials_yml = File.join(config_dir, "pipeline_credentials.yml")
      ceb.create_file_from_prereqs(pipeline_credentials_yml, "pipeline_credentials", generated_pipeline_credentials)

      login_into_fly

      run_cmd upload_pipelines_command(pipeline_credentials_yml)
    end

    def unpause_pipelines
      login_into_fly
      run_cmd "fly --target concourse-target unpause-pipeline --pipeline bootstrap-all-init-pipelines"
    end

    def trigger_jobs
      login_into_fly
      run_cmd "fly --target concourse-target trigger-job --job bootstrap-all-init-pipelines/bootstrap-init-pipelines"
    end

    def creds
      creds_source = own_concourse_vars || ceb.env_creator_adapter.vars
      {
        "target"   => creds_source["concourse_target"] || ceb.env_creator_adapter.concourse_target,
        "url"      => creds_source["concourse_url"],
        "username" => creds_source["concourse_username"],
        "password" => creds_source["concourse_password"],
        "insecure" => creds_source["concourse_insecure"] || "true"
      }
    end

    private

    # insecure by default, not an option yet
    def login_into_fly
      run_cmd "fly login --target concourse-target \
--concourse-url #{creds['url']} \
--username '#{creds['username']}' \
--password '#{creds['password']}' -k && \
fly --target concourse-target sync"
    end

    def own_concourse_vars
      ceb.prereqs["concourse"]
    end

    def upload_pipelines_command(pipeline_credentials_yml)
      git_server_ip = ceb.git.server_ip

      "fly --target concourse-target set-pipeline --non-interactive \
--pipeline bootstrap-all-init-pipelines \
--config #{CoaEnvBootstrapper::PROJECT_ROOT_DIR}/concourse/pipelines/bootstrap-all-init-pipelines.yml \
--load-vars-from #{pipeline_credentials_yml} \
--var paas-templates-uri='git://#{git_server_ip}/paas-templates' \
--var secrets-uri='git://#{git_server_ip}/secrets' \
--var concourse-micro-depls-target='#{creds['url']}' \
--var concourse-micro-depls-username='#{creds['username']}' \
--var concourse-micro-depls-password='#{creds['password']}'"
    end
  end
end
