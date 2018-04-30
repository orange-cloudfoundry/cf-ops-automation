require 'yaml'

class RootDeploymentVersion
  attr_reader :root_deployment_name, :versions

  DEPLOYMENT_NAME = 'deployment-name'.freeze
  STEMCELL_VERSION = 'stemcell-version'.freeze
  STEMCELL_NAME = 'stemcell-name'.freeze

  def initialize(root_deployment_name, versions)
    @root_deployment_name = root_deployment_name
    @versions = versions
    validate
  end

  def self.load_file(filename)
    raise "file not found: #{filename}" unless File.exist?(filename)

    loaded_versions = YAML.load_file(filename) || {}
    name = loaded_versions ? loaded_versions[DEPLOYMENT_NAME] : loaded_versions

    RootDeploymentVersion.new(name, loaded_versions)
  end

  def self.init_file(root_deployment_name, versions = {}, output_path = '/tmp')
    filename = File.join(output_path, get_filename(root_deployment_name))
    raise "file already exists: #{filename}" if File.exist?(filename)

    versions[DEPLOYMENT_NAME] = root_deployment_name
    add_required_keys_and_value(versions)
    File.open(filename, 'w') { |file| file.write(versions.to_yaml) }
  end

  def self.add_required_keys_and_value(versions)
    versions[STEMCELL_NAME] = 'aStemCell' unless versions[STEMCELL_NAME]
    versions[STEMCELL_VERSION] = 1 unless versions[STEMCELL_VERSION]
  end

  def self.get_filename(root_deployment_name)
    "#{root_deployment_name}-versions.yml"
  end

  private

  def validate
    validate_versions
    validate_deployment_name
    validate_stemcell_version
  end

  def validate_versions
    raise "empty versions" unless versions
  end

  def validate_deployment_name
    deployment_name = versions[DEPLOYMENT_NAME]
    raise "invalid #{DEPLOYMENT_NAME}" if deployment_name.to_s.empty?
    raise "invalid/missing #{DEPLOYMENT_NAME}: found #{deployment_name} expected #{root_deployment_name}" if deployment_name != root_deployment_name
  end

  def validate_stemcell_version
    raise "invalid/missing #{STEMCELL_VERSION}" if versions[STEMCELL_VERSION].to_s.empty?
  end
end
