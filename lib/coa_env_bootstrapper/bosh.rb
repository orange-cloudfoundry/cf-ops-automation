require_relative './base'
require_relative '../concerns/coa_bosh_client'

module CoaEnvBootstrapper
  # Manage interaction with a Bosh Director (stemcell upload, cloud config, prerequisite deployment,etc..) during bootstrap
  class Bosh < Base
    attr_reader :config_source

    def initialize(config_source)
      @config_source = config_source
    end

    def upload_stemcell(stemcell_config)
      raise NoActiveStepConfigError.new('stemcell', 'upload_stemcell') unless stemcell_config

      name     = stemcell_config["name"]
      version  = stemcell_config["version"]
      uri      = stemcell_config["uri"]
      sha      = stemcell_config["sha"]

      if bosh_client.stemcell_uploaded?(name, version)
        logger.log_and_puts :info, "Stemcell #{name}/#{version} already uploaded."
      else
        bosh_client.upload_stemcell(uri, sha)
      end
    end

    def update_cloud_config(cloud_config)
      raise NoActiveStepConfigError.new('cloud_config', 'update_cloud_config') unless cloud_config

      file = Tempfile.new("cloud-config.yml")
      file.write(cloud_config.to_yaml)
      file.close
      bosh_client.update_cloud_config(file.path)
    ensure
      file&.unlink
    end

    def deploy_git_server(manifest)
      raise NoActiveStepConfigError.new('git_server_manifest', 'git_server_manifest') unless manifest

      if bosh_client.release_uploaded?("git-server", "3")
        logger.log_and_puts :info, "BOSH release git-server/3 already uploaded."
      else
        bosh_client.upload_release("https://bosh.io/d/github.com/cloudfoundry-community/git-server-release?v=3", "682a70517c495455f43545b9ae39d3f11d24d94c")
      end

      file = Tempfile.new("git-server.yml")
      file.write(manifest.to_yaml)
      file.close
      bosh_client.deploy("git-server", file.path)
    ensure
      file&.unlink
    end

    def git_server_ip
      @git_server_ip ||= bosh_client.deployment_first_vm_ip("git-server")
    end

    def config
      {
        "environment"   => config_source["bosh_environment"],
        "target"        => config_source["bosh_target"],
        "client"        => config_source["bosh_client"],
        "client-secret" => config_source["bosh_client_secret"],
        "ca-cert"       => config_source["bosh_ca_cert"]
      }
    end

    def bosh_client
      @bosh_client ||= CoaBoshClient.new(config)
    end
  end
end
