require_relative './base'
require_relative '../utils/bosh'

module Coa
  module EnvBootstrapper
    # Manage interaction with a Bosh Director (stemcell upload, cloud config,
    # prerequisite deployment,etc..) during bootstrap
    class Bosh < Base
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def prepare_environment(prereqs)
        logger.log_and_puts :debug, 'Preparing BOSH environment'
        upload_stemcell(prereqs.stemcell)              unless prereqs.inactive_step?("upload_stemcell")
        update_cloud_config(prereqs.cloud_config)      unless prereqs.inactive_step?("update_cloud_config")
        deploy_git_server(prereqs.git_server_manifest) unless prereqs.inactive_step?("deploy_git_server")
      end

      def upload_stemcell(stemcell_config)
        raise NoActiveStepConfigError.new('stemcell', 'upload_stemcell') unless stemcell_config

        name     = stemcell_config["name"]
        version  = stemcell_config["version"]
        uri      = stemcell_config["uri"]
        sha      = stemcell_config["sha"]

        if client.stemcell_uploaded?(name, version)
          logger.log_and_puts :info, "Stemcell #{name}/#{version} already uploaded."
        else
          client.upload_stemcell(uri, sha)
        end
      end

      def update_cloud_config(cloud_config)
        raise NoActiveStepConfigError.new('cloud_config', 'update_cloud_config') if cloud_config.to_s.empty?

        file = Tempfile.new("cloud-config.yml")
        file.write(cloud_config.to_yaml)
        file.close
        client.update_cloud_config(file.path)
      ensure
        file&.unlink
      end

      def deploy_git_server(manifest)
        raise NoActiveStepConfigError.new('git_server_manifest', 'git_server_manifest') unless manifest

        if client.release_uploaded?("git-server", "3")
          logger.log_and_puts :info, "BOSH release git-server/3 already uploaded."
        else
          client.upload_release("https://bosh.io/d/github.com/cloudfoundry-community/git-server-release?v=3", "682a70517c495455f43545b9ae39d3f11d24d94c")
        end

        file = Tempfile.new("git-server.yml")
        file.write(manifest.to_yaml)
        file.close
        client.deploy("git-server", file.path)
      ensure
        file&.unlink
      end

      def git_server_ip
        @git_server_ip ||= client.deployment_first_vm_ip("git-server")
      end

      def client
        @client ||= Coa::Utils::Bosh::Client.new(config)
      end
    end
  end
end
