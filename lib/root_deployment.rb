require 'yaml'
require_relative 'deployment_factory'
require_relative 'deployment_deployers_config'

class RootDeployment
  attr_reader :root_deployment_name, :dependency_root_path, :enable_deployment_root_path, :excluded_file
  ENABLE_DEPLOYMENT_FILENAME = 'enable-deployment.yml'.freeze
  DEFAULT_EXCLUDE = %w[secrets cf-apps-deployments terraform-config template].freeze

  def initialize(root_deployment_name, dependency_root_path, enable_deployment_root_path, exclude_list = DEFAULT_EXCLUDE)
    @root_deployment_name = root_deployment_name
    @dependency_root_path = dependency_root_path
    @enable_deployment_root_path = enable_deployment_root_path
    @excluded_file = exclude_list

    raise 'invalid root_deployment_name' unless validate_string @root_deployment_name
    raise 'invalid dependency_root_path' unless validate_string @dependency_root_path
    raise 'invalid enable_deployment_root_path' unless validate_string @enable_deployment_root_path
  end

  def overview_from_hash(deployment_factory)
    dependencies = {}

    enable_deployment_scan = File.join(@enable_deployment_root_path, @root_deployment_name, '/*')
    puts "Path deployment overview: #{enable_deployment_scan}"
    Dir[enable_deployment_scan]
      &.select { |f| File.directory?(f) && !@excluded_file.include?(f.split(File::SEPARATOR).last) }
      &.each do |filename|
        dirname = filename.split(File::SEPARATOR).last
        puts "Processing #{dirname}"
        enable_deployment_file = File.join(filename, ENABLE_DEPLOYMENT_FILENAME)

        if File.exist?(enable_deployment_file)
          base_location = File.join(@dependency_root_path, @root_deployment_name, dirname)

          deployers_config = DeploymentDeployersConfig.new(dirname, base_location, filename, deployment_factory)
          deployment = deployers_config.load_configs
          dependencies[deployment.name] = deployment.details
          raise "#{filename} - Invalid deployment: expected <#{dirname}> - Found <#{deployment.name}>" if deployment.name != dirname
        else
          puts "Deployment #{dirname} is inactive"
          # base_location = File.join(@dependency_root_path, @root_deployment_name, dirname)
          #
          # deployers_config = DeploymentDeployersConfig.new(dirname, base_location, filename, deployment_factory)
          # deployment = deployers_config.load_configs
          # deployment.disable
          # dependencies[deployment.name] = deployment.details

          current_deployment = Deployment.new(dirname).disable
          dependencies[current_deployment.name] = current_deployment.details
        end
        # puts "##############################"
        #    dependencies.each do |aDep|
        #        puts aDep
        #    end
        # puts "##############################"
      end
    puts "Dependencies loaded: \n#{YAML.dump(dependencies)}"
    dependencies
  end

  def extract_deployment(name, overview)
    details = overview[name]
    raise "cannot extract deployment #{name} from overview" if details.nil?
    Deployment.new(name, details)
  end


  private

  def validate_string(a_string)
    !(a_string.nil? || !a_string.is_a?(String) || a_string.empty?)
  end
end
