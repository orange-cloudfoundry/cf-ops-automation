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
    if loaded_versions
      name = loaded_versions[DEPLOYMENT_NAME]
    else
      name = loaded_versions
    end

    RootDeploymentVersion.new(name, loaded_versions)
  end

  def self.init_file(root_deployment_name, versions = {}, output_path = '/tmp')
    filename = File.join(output_path, get_filename(root_deployment_name))
    raise "file already exists: #{filename}" if File.exist?(filename)

    versions[DEPLOYMENT_NAME] = root_deployment_name
    add_required_keys_and_value(versions)
    File.open(filename, 'w') { |file| file.write(versions.to_yaml) }
  end


  private

  def validate
    raise "empty versions" unless @versions
    raise "invalid #{DEPLOYMENT_NAME}" unless validate_string(@versions[DEPLOYMENT_NAME])
    raise "invalid/missing #{DEPLOYMENT_NAME}: found #{@versions[DEPLOYMENT_NAME]} expected #{@root_deployment_name}" unless @versions[DEPLOYMENT_NAME] == @root_deployment_name
    raise "invalid/missing #{STEMCELL_NAME}" unless validate_string(@versions[STEMCELL_NAME])
    raise "invalid/missing #{STEMCELL_VERSION}" if @versions[STEMCELL_VERSION].nil? || (@versions[STEMCELL_VERSION].is_a?(String) && @versions[STEMCELL_VERSION].empty?)
  end

  def self.add_required_keys_and_value(versions)
    versions[STEMCELL_NAME]='aStemCell' unless versions[STEMCELL_NAME]
    versions[STEMCELL_VERSION]=1 unless versions[STEMCELL_VERSION]
  end

  def self.get_filename(root_deployment_name)
    "#{root_deployment_name}-versions.yml"
  end

  def validate_string(a_string)
    !(a_string.nil? || !a_string.is_a?(String) || a_string.empty?)
  end
end
