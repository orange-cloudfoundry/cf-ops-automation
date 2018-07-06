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

    raise 'invalid root_deployment_name' if @root_deployment_name.to_s.empty?
    raise 'invalid dependency_root_path' if @dependency_root_path.to_s.empty?
    raise 'invalid enable_deployment_root_path' if @enable_deployment_root_path.to_s.empty?
  end

  def overview_from_hash(deployment_factory)
    dependencies = {}

    select_deployment_scan_files&.each do |filename|
      dirname = filename.split(File::SEPARATOR).last
      puts "Processing #{dirname}"

      enable_deployment_file = File.join(filename, ENABLE_DEPLOYMENT_FILENAME)
      deployment = if File.exist?(enable_deployment_file)
                     base_location = File.join(@dependency_root_path, @root_deployment_name, dirname)
                     deployers_config = DeploymentDeployersConfig.new(dirname, base_location, filename, deployment_factory)
                     deployers_config.load_configs
                   else
                     puts "Deployment #{dirname} is inactive"
                     Deployment.new(dirname).disable
                   end

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

  def select_deployment_scan_files
    enable_deployment_scan = File.join(@enable_deployment_root_path, @root_deployment_name, '/*')
    puts "Path deployment overview: #{enable_deployment_scan}"

    Dir[enable_deployment_scan]&.select do |file|
      File.directory?(file) && !@excluded_file.include?(file.split(File::SEPARATOR).last)
    end
  end
end
