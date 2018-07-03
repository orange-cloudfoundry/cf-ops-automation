require 'tmpdir'
require 'yaml'

module CoaEnvBootstrapper
  require 'coa_env_bootstrapper/bosh'
  require 'coa_env_bootstrapper/git'
  require 'coa_env_bootstrapper/concourse'
  require 'coa_env_bootstrapper/env_creator_adapter'

  class Base
    attr_reader :bosh, :env_creator_adapter, :concourse, :git, :prereqs, :tmpdir

    def initialize(prereqs_paths)
      @prereqs             = load_prereqs(prereqs_paths)
      @tmpdir              = Dir.mktmpdir
      @env_creator_adapter = EnvCreatorAdapter.new(self, "bucc")
      @bosh                = Bosh.new(self)
      @concourse           = Concourse.new(self)
      @git                 = Git.new(self)
    end

    def run
      # TODO: check_prereqs
      env_creator_adapter.deploy_transiant_infra if step_active?("deploy_transiant_infra")
      write_source_file
      bosh.prepare_environment
      git.prepare_environment
      concourse.run_pipeline_jobs
      self
    end

    def clean
      FileUtils.remove_entry_secure @tmpdir
    end

    def write_source_file
      @source_file_path = File.join(@tmpdir, CoaEnvBootstrapper::SOURCE_FILE_NAME)
      File.write(@source_file_path, source_profile)
    end

    def generated_concourse_credentials
      # TODO: make concourse credentials keys dynamic
      {
        "bosh-target"   => bosh_creds["target"],
        "bosh-username" => bosh_creds["client"],
        "bosh-password" => bosh_creds["client_secret"],
        "bosh-ca-cert"  => bosh_creds["ca_cert"],
        "secrets-uri"        => "git://#{git.server_ip}/secrets",
        "paas-templates-uri" => "git://#{git.server_ip}/paas-templates",
        "concourse-micro-depls-target"   => concourse_creds["url"],
        "concourse-micro-depls-username" => concourse_creds["username"],
        "concourse-micro-depls-password" => concourse_creds["password"],
        "concourse-hello-world-root-depls-insecure" => concourse_creds["insecure"],
        "concourse-hello-world-root-depls-password" => concourse_creds["password"],
        "concourse-hello-world-root-depls-target"   => concourse_creds["url"],
        "concourse-hello-world-root-depls-username" => concourse_creds["username"]
      }
    end

    private

    def source_profile
      bosh_creds.
        map { |key, value| "export BOSH_#{key.upcase}='#{value}'" }.
        join("\n")
    end

    def concourse_creds
      creds_source = own_concourse_vars || env_creator_adapter.vars
      {
        "target"   => creds_source["concourse_target"] || env_creator_adapter.concourse_target,
        "url"      => creds_source["concourse_url"],
        "username" => creds_source["concourse_username"],
        "password" => creds_source["concourse_password"],
        "insecure" => creds_source["concourse_insecure"] || "true"
      }
    end

    def bosh_creds
      creds_source = own_bosh_vars || env_creator_adapter.vars
      {
        "environment"   => creds_source["bosh_environment"],
        "target"        => creds_source["bosh_target"],
        "client"        => creds_source["bosh_client"],
        "client_secret" => creds_source["bosh_client_secret"],
        "ca_cert"       => creds_source["bosh_ca_cert"]
      }
    end

    # def output_dir
    #   @output_dir ||=
    #     begin
    #       path = File.join(tmpdir, ::OUTPUT_DIR_NAME)
    #       Dir.mkdir_p path
    #       path
    #   end
    # end

    def create_file_from_prereqs(filepath, prereqs_key, additional_info = {})
      file = File.new(filepath, 'w+')
      credentials_content = prereqs[prereqs_key].merge(additional_info)
      file.write(YAML.dump(credentials_content))
      file.close
      filepath
    end

    def own_concourse_vars
      prereqs["concourse"]
    end

    def own_bosh_vars
      prereqs["bosh"]
    end

    def steps
      {
        "deploy_transiant_infra" => true,
        "upload_stemcell"        => true,
        "upload_cloud_config"    => true,
        "install_git_server"     => true
      }.merge(@prereqs["steps"].to_h)
    end


    def step_active?(step_key)
      steps[step_key]
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
