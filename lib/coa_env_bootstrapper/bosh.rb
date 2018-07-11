require_relative './command_runner'

module CoaEnvBootstrapper
  # Manage interaction with a Bosh Director (stemcell upload, cloud config, prerequisite deployment,etc..) during bootstrap
  class Bosh
    include CommandRunner

    attr_reader :ceb

    def initialize(coa_env_bootstrapper)
      @ceb = coa_env_bootstrapper
    end

    def upload_stemcell
      info = ceb.prereqs["stemcell"]
      name = info["name"]
      version = info["version"]
      uri = info["uri"]
      sha = info["sha"]

      if stemcell_is_uploaded?(name, version)
        puts "Stemcell #{name}/#{version} already uploaded."
      else
        run_cmd "bosh -n upload-stemcell --sha1 #{sha} #{uri}", source_file_path: ceb.source_profile_path
      end
    end

    def upload_cloud_config(config_dir)
      cloud_config_yml = File.join(config_dir, "cloud-config.yml")
      ceb.create_file_from_prereqs(cloud_config_yml, "cloud_config")
      run_cmd "bosh -n update-cloud-config #{cloud_config_yml}", source_file_path: ceb.source_profile_path
    end

    def deploy_git_server(config_dir)
      if bosh_release_is_uploaded?("git-server", "3")
        puts "BOSH release git-server/3 already uploaded."
      else
        run_cmd "bosh upload-release --sha1 682a70517c495455f43545b9ae39d3f11d24d94c \
https://bosh.io/d/github.com/cloudfoundry-community/git-server-release?v=3", source_file_path: ceb.source_profile_path
      end

      git_server_manifest = File.join(config_dir, "git-server.yml")
      ceb.create_file_from_prereqs(git_server_manifest, "git_server_manifest")

      run_cmd "bosh -n deploy -d git-server #{git_server_manifest} -v repos=[paas-templates,secrets]", source_file_path: ceb.source_profile_path
    end

    def creds
      creds_source = own_bosh_vars || ceb.env_creator_adapter.vars
      {
        "environment"   => creds_source["bosh_environment"],
        "target"        => creds_source["bosh_target"],
        "client"        => creds_source["bosh_client"],
        "client-secret" => creds_source["bosh_client_secret"],
        "ca-cert"       => creds_source["bosh_ca_cert"]
      }
    end

    private

    def own_bosh_vars
      ceb.prereqs["bosh"]
    end

    def stemcell_is_uploaded?(name, version)
      run_cmd("bosh stemcells --column name --column version | cut -f1,2", source_file_path: ceb.source_profile_path).
        split("\n").map(&:split).
        keep_if do |stemcell|
        stemcell[0] == name && stemcell[1].match(/#{version}\*{0,1}/)
      end.first
    end

    def bosh_release_is_uploaded?(name, version)
      run_cmd("bosh releases --column name --column version | cut -f1,2", source_file_path: ceb.source_profile_path).
        split("\n").map(&:split).
        keep_if do |release|
        release[0] == name && release[1].match(/#{version}\*{0,1}/)
      end.first
    end
  end
end
