require 'tmpdir'
require 'yaml'
require_relative './bosh'
require_relative './git'
require_relative './concourse'
require_relative './env_creator_adapter'
require_relative './command_runner'

module CoaEnvBootstrapper
  class Base
    attr_reader :bosh, :config_dir, :concourse, :env_creator_adapter, :git, :prereqs

    def initialize(prereqs_paths)
      @prereqs             = load_prereqs(prereqs_paths)
      @env_creator_adapter = EnvCreatorAdapter.new("bucc", @prereqs)
      @bosh                = Bosh.new(self)
      @git                 = Git.new(self)
      @concourse           = Concourse.new(self)
    end

    def self.run(prereqs_path)
      ceb = new(prereqs_path)
      ceb.run
    ensure
      ceb&.config_dir && FileUtils.remove_entry_secure(ceb.config_dir)
    end

    def run
      @config_dir = Dir.mktmpdir
      write_source_profile
      env_creator_adapter.deploy_transient_infra unless inactive_step?("deploy_transient_infra")
      prepare_bosh_environment
      prepare_git_environment
      run_pipeline_jobs
      env_creator_adapter.display_concourse_login_information unless inactive_step?("deploy_transient_infra")
    end

    def generated_concourse_credentials
      # TODO: make concourse credentials keys dynamic
      bosh_creds = bosh.creds
      git_server_ip = git.server_ip
      concourse_creds = concourse.creds
      {
        "bosh-target"      => bosh_creds["target"],
        "bosh-username"    => bosh_creds["client"],
        "bosh-password"    => bosh_creds["client-secret"],
        "bosh-ca-cert"     => bosh_creds["ca-cert"],
        "bosh-environment" => bosh_creds["target"],
        "secrets-uri"        => "git://#{git_server_ip}/secrets",
        "paas-templates-uri" => "git://#{git_server_ip}/paas-templates",
        "concourse-hello-world-root-depls-insecure" => concourse_creds["insecure"],
        "concourse-hello-world-root-depls-password" => concourse_creds["password"],
        "concourse-hello-world-root-depls-target"   => concourse_creds["url"],
        "concourse-hello-world-root-depls-username" => concourse_creds["username"]
      }
    end

    def create_file_from_prereqs(filepath, prereqs_key, additional_info = {})
      file = File.new(filepath, 'w+')
      credentials_content = prereqs[prereqs_key]&.merge(additional_info) || {}
      file.write(YAML.dump(credentials_content))
      file.close
      filepath
    end

    def source_profile_path
      File.join(config_dir, CoaEnvBootstrapper::SOURCE_FILE_NAME)
    end

    def write_source_profile
      File.write(source_profile_path, source_profile)
    end

    private

    def prepare_bosh_environment
      bosh.upload_stemcell                 unless inactive_step?("upload_stemcell")
      bosh.upload_cloud_config(config_dir) unless inactive_step?("upload_cloud_config")
      bosh.deploy_git_server(config_dir)   unless inactive_step?("deploy_git_server")
    end

    def prepare_git_environment
      git.push_templates_repo
      git.push_secrets_repo
      git.download_git_dependencies
    end

    def run_pipeline_jobs
      concourse.upload_pipelines(config_dir, generated_concourse_credentials)
      concourse.unpause_pipelines
      concourse.trigger_jobs
    end

    def source_profile
      bosh.creds.
        map { |key, value| "export BOSH_#{key.tr('-', '_').upcase}='#{value}'" }.
        join("\n")
    end

    def inactive_step?(step)
      @prereqs["inactive_steps"]&.include?(step)
    end

    def load_prereqs(prereqs_paths)
      prereqs = {}

      prereqs_paths.each do |path|
        if File.exist?(path)
          prereqs = prereqs.merge(YAML.load_file(path))
        else
          puts "File #{path} not found. Will be ignored."
        end
      end

      prereqs
    end
  end
end
