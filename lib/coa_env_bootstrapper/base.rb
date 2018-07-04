require 'tmpdir'
require 'yaml'
require_relative './bosh'
require_relative './git'
require_relative './concourse'
require_relative './env_creator_adapter'
require_relative './command_runner'

module CoaEnvBootstrapper
  class Base
    attr_accessor :config_dir
    attr_reader :bosh, :env_creator_adapter, :concourse, :git, :prereqs

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
      FileUtils.remove_entry_secure ceb.config_dir if ceb.config_dir
    end

    def run
      @config_dir = Dir.mktmpdir
      write_source_profile
      env_creator_adapter.deploy_transiant_infra unless inactive_step?("deploy_transiant_infra")
      prepare_bosh_environment
      prepare_git_environment
      run_pipeline_jobs
      env_creator_adapter.display_concourse_login_information
    end

    def generated_concourse_credentials
      # TODO: make concourse credentials keys dynamic
      {
        "bosh-target"      => bosh.creds["target"],
        "bosh-username"    => bosh.creds["client"],
        "bosh-password"    => bosh.creds["client-secret"],
        "bosh-ca-cert"     => bosh.creds["ca-cert"],
        "bosh-environment" => bosh.creds["target"],
        "secrets-uri"        => "git://#{git.server_ip}/secrets",
        "paas-templates-uri" => "git://#{git.server_ip}/paas-templates",
        # "concourse-micro-depls-target"   => concourse.creds["url"],
        # "concourse-micro-depls-username" => concourse.creds["username"],
        # "concourse-micro-depls-password" => concourse.creds["password"],
        "concourse-hello-world-root-depls-insecure" => concourse.creds["insecure"],
        "concourse-hello-world-root-depls-password" => concourse.creds["password"],
        "concourse-hello-world-root-depls-target"   => concourse.creds["url"],
        "concourse-hello-world-root-depls-username" => concourse.creds["username"]
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
        map { |key, value| "export BOSH_#{key.tr("-", "_").upcase}='#{value}'" }.
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
