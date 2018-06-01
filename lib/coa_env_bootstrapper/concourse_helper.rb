class CoaEnvBootstrapper
  module ConcourseHelper
    def upload_pipelines
      concourse_credentials_yml = File.join(@tmpdir, "concourse-credentials.yml")
      create_file_from_prereqs(concourse_credentials_yml, "concourse_credentials", generated_concourse_credentials)

      login_into_fly

      run_cmd "fly --target #{concourse_creds["target"]} set-pipeline --non-interactive \
--pipeline bootstrap-all-init-pipelines \
--config #{PROJECT_ROOT_DIR}/concourse/pipelines/bootstrap-all-init-pipelines.yml \
--load-vars-from #{concourse_credentials_yml} \
--var paas-templates-uri='git://#{git_server_ip}/paas-templates' \
--var secrets-uri='git://#{git_server_ip}/secrets' \
--var concourse-micro-depls-target=#{concourse_creds["url"]} \
--var concourse-micro-depls-username=#{concourse_creds["username"]} \
--var concourse-micro-depls-password=#{concourse_creds["password"]}", source: true
    end

    def unpause_pipelines
      login_into_fly
      run_cmd "fly --target #{concourse_creds["target"]} unpause-pipeline --pipeline bootstrap-all-init-pipelines"
    end

    def trigger_jobs
      login_into_fly
      run_cmd "fly --target #{concourse_creds["target"]} trigger-job --job bootstrap-all-init-pipelines/bootstrap-init-pipelines"
    end

    # insecure by default, not an option yet
    def login_into_fly
      run_cmd "fly login --target #{concourse_creds["target"]} \
--concourse-url #{concourse_creds["url"]} \
--username=#{concourse_creds["username"]} \
--password=#{concourse_creds["password"]} -k && \
fly --target #{concourse_creds["target"]} sync",
        source: true
    end
  end
end
