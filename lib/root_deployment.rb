require 'yaml'
require_relative 'deployment_factory'
require_relative './deployment_deployers_config'

class RootDeployment
  attr_reader :root_deployment_name, :dependency_root_path, :enable_deployment_root_path, :excluded_file, :fail_on_inconsistency

  ENABLE_DEPLOYMENT_FILENAME = 'enable-deployment.yml'.freeze
  DEFAULT_EXCLUDE = %w[secrets cf-apps-deployments terraform-config template].freeze

  def initialize(root_deployment_name, dependency_root_path, enable_deployment_root_path, exclude_list: DEFAULT_EXCLUDE, fail_on_inconsistency: true)
    @root_deployment_name = root_deployment_name
    @dependency_root_path = dependency_root_path
    @enable_deployment_root_path = enable_deployment_root_path
    @excluded_file = exclude_list
    @fail_on_inconsistency = fail_on_inconsistency

    raise 'invalid root_deployment_name' if @root_deployment_name.to_s.empty?
    raise 'invalid dependency_root_path' if @dependency_root_path.to_s.empty?
    raise 'invalid enable_deployment_root_path' if @enable_deployment_root_path.to_s.empty?
  end

  def overview_from_hash(deployment_factory)
    dependencies = {}
    select_deployment_scan_files&.each do |enable_deployment_path|
      dirname = enable_deployment_path.split(File::SEPARATOR).last
      puts "Processing #{dirname}"
      deployers_config = create_deployment_deployer_config(dirname, deployment_factory, enable_deployment_path)
      deployment = load_deployment_config_files(dirname, deployers_config, enable_deployment_path)
      dependencies[deployment.name] = deployment.details
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

  def create_deployment_deployer_config(deployment_name, deployment_factory, filename)
    base_location = File.join(@dependency_root_path, @root_deployment_name, deployment_name)
    DeploymentDeployersConfig.new(deployment_name, base_location, filename, deployment_factory, fail_on_inconsistency: @fail_on_inconsistency)
  end

  def load_deployment_config_files(deployment_name, deployers_config, enable_deployment_path)
    enable_deployment_file = File.join(enable_deployment_path, ENABLE_DEPLOYMENT_FILENAME)

    if File.exist?(enable_deployment_file)
      deployers_config.load_configs
    else
      puts "Deployment #{deployment_name} is inactive, ignoring inconsistencies."
      begin
        deployers_config.load_configs.disable
      rescue RuntimeError => e
        raise e unless e.message.start_with?("Inconsistency detected: deployment <#{deployment_name}> is marked as active")

        Deployment.new(deployment_name).disable
      end
    end
  end

  def select_deployment_scan_files
    enable_deployment_scan = File.join(@enable_deployment_root_path, @root_deployment_name, '/*')
    puts "Path deployment overview: #{enable_deployment_scan}"

    Dir[enable_deployment_scan]&.select do |file|
      File.directory?(file) && !@excluded_file.include?(file.split(File::SEPARATOR).last)
    end
  end
end
