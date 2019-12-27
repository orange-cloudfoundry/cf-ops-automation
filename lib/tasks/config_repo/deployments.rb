module Tasks
  module ConfigRepo
    # ease config-repository manipulations
    class Deployments
      def initialize(config_repo_name = 'config-resource')
        root_deployment_name = ENV.fetch('ROOT_DEPLOYMENT_NAME', '')
        raise Tasks::Bosh::EnvVarMissing, "missing environment variable: ROOT_DEPLOYMENT_NAME" if root_deployment_name.to_s.empty?

        @config_repo_name = config_repo_name
        @root_deployment_name = root_deployment_name
        @root_deployment_dir = File.join(@config_repo_name, @root_deployment_name)
      end

      def filter_deployments(marker_filename)
        deployment_files = Dir[File.join(@config_repo_name, @root_deployment_name, '**', marker_filename)]
        deployments = deployment_files.map { |filename| File.dirname(filename)&.split("/")&.last }&.sort
        puts "Selected deployments (matching #{marker_filename}: #{deployments}"
        deployments
      end

      def protected_deployments
        filter_deployments('protect-deployment.yml')
      end

      def enabled_deployments
        filter_deployments('enable-deployment.yml')
      end

      def bosh_deployments
        deployments = []
        Dir.each_child(@root_deployment_dir) do |deployment_dirname|
          manifest_dir = File.join(@root_deployment_dir, deployment_dirname)
          deployments << deployment_dirname if deployment?(manifest_dir, deployment_dirname)
        end
        deployments.sort
      end

      def deployment?(manifest_dir, name)
        return false if name == 'secrets'

        manifest_path = File.join(manifest_dir, name + '.yml')
        manifest_failure_path = File.join(manifest_dir, name + '-last-deployment-failure.yml')
        File.exist?(manifest_path) || File.exist?(manifest_failure_path)
      end

      def cleanup_disabled_deployments
        puts "Cleanup deployments directory in config repository"
        deployments_to_cleanup = disabled_deployments
        deployments_to_cleanup.each { |deployment_name| puts cleanup_deployment(deployment_name) }
        deployments_to_cleanup
      end

      def cleanup_deployment(deployment_name)
        puts "Cleanup deployment #{deployment_name}"
        base_path = File.join(@root_deployment_dir, deployment_name)
        %W[#{deployment_name}.yml #{deployment_name}-last-deployment-failure.yml #{deployment_name}-fingerprints.json].each do |filename|
          full_path = File.join(base_path, filename)
          File.delete(full_path) if File.exist?(full_path)
        end
        Dir.delete(base_path) if Dir.exist?(base_path) && Dir.empty?(base_path)
      end

      def disabled_deployments
        expected_deployments_list = enabled_deployments
        protected_deployments_list = protected_deployments
        bosh_deployments.delete_if { |deployment_name| expected_deployments_list&.include?(deployment_name) || protected_deployments_list&.include?(deployment_name) }
      end
    end
  end
end
