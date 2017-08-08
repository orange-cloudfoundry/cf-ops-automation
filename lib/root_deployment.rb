require 'yaml'
require_relative 'deployment_factory.rb'

class RootDeployment
  DEPLOYMENT_DEPENDENCIES_FILENAME = 'deployment-dependencies.yml'.freeze
  ENABLE_DEPLOYMENT_FILENAME = 'enable-deployment.yml'.freeze

  def initialize(root_deployment_name, dependency_root_path, enable_deployment_root_path)
    @root_deployment_name = root_deployment_name
    @dependency_root_path = dependency_root_path
    @enable_deployment_root_path = enable_deployment_root_path

    raise 'invalid root_deployment_name' unless validate_string @root_deployment_name
    raise 'invalid dependency_root_path' unless validate_string @dependency_root_path
    raise 'invalid enable_deployment_root_path' unless validate_string @enable_deployment_root_path
  end

  def overview_from_hash(deployment_factory)
    dependencies = {}
    puts "Path deployment overview: #{@enable_deployment_root_path}"

    Dir[@enable_deployment_root_path]
      .select { |f| File.directory? f }
      .each do |filename|
        dirname = filename.split(File::SEPARATOR).last
        puts "Processing #{dirname}"
        Dir[File.join(filename, ENABLE_DEPLOYMENT_FILENAME)].each do |enable_deployment_filename|
          dependency_filename = File.join(@dependency_root_path, @root_deployment_name, dirname, DEPLOYMENT_DEPENDENCIES_FILENAME)

          puts "Bosh release detected: #{dirname}"
          raise "Inconsistency detected: found #{enable_deployment_filename}, but no #{DEPLOYMENT_DEPENDENCIES_FILENAME} found at #{dependency_filename}" unless File.exist?(dependency_filename)

          deployment_factory.load_file(dependency_filename).each do |deployment|
            dependencies[deployment.name] = deployment.details
            raise "#{filename} - Invalid deployment: expected <#{dirname}> - Found <#{deployment.name}>" if deployment.name != dirname
          end
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

  private

  def validate_string(a_string)
    !(a_string.nil? || !a_string.is_a?(String) || a_string.empty?)
  end
end
