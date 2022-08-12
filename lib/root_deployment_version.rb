require 'yaml'

class RootDeploymentVersion
  attr_reader :root_deployment_name, :versions

  ROOT_DEPLOYMENT_NAME = 'name'.freeze
  DEPRECATED_DEPLOYMENT_NAME = 'deployment-name'.freeze
  STEMCELL = 'stemcell'.freeze
  STEMCELL_VERSION = 'version'.freeze
  STEMCELL_NAME = 'stemcell-name'.freeze
  DEFAULT_BASE_LOCATION = 'https://github.com/'.freeze

  def initialize(root_deployment_name, versions)
    @root_deployment_name = root_deployment_name
    @versions = versions
    puts '*' * 10 + "\nRootDeploymentVersion:\n#{versions.to_yaml}"
    validate
  end

  def self.load_file(filename)
    raise "file not found: #{filename}" unless File.exist?(filename)

    loaded_versions = YAML.load_file(filename, aliases: true) || {}
    name = loaded_versions ? loaded_versions[ROOT_DEPLOYMENT_NAME] : loaded_versions

    add_default_base_location(loaded_versions)
    RootDeploymentVersion.new(name, loaded_versions)
  end

  def self.init_file(root_deployment_name, versions = {}, output_path = '/tmp')
    filename = File.join(output_path, get_filename(root_deployment_name))
    raise "file already exists: #{filename}" if File.exist?(filename)

    versions[ROOT_DEPLOYMENT_NAME] = root_deployment_name
    add_required_keys_and_value(versions)
    File.open(filename, 'w') { |file| file.write(versions.to_yaml) }
  end

  def self.add_required_keys_and_value(versions)
    stemcell = versions.dig(STEMCELL) || {}
    stemcell[STEMCELL_NAME] = 'aStemCell' unless stemcell[STEMCELL_NAME]
    stemcell[STEMCELL_VERSION] = 1 unless stemcell[STEMCELL_VERSION]
    versions.store(STEMCELL, stemcell)
    add_default_base_location(versions)
  end

  def self.get_filename(root_deployment_name)
    "root-deployment.yml"
  end

  private

  def self.add_default_base_location(loaded_versions)
    loaded_versions['releases'] = loaded_versions.dig('releases')&.transform_values! do |release|
      if release['base_location'].to_s.empty?
        release.deep_merge('base_location' => DEFAULT_BASE_LOCATION)
      else
        release
      end
    end
  end

  def validate
    validate_versions
    validate_deployment_name
    validate_stemcell_version
  end

  def validate_versions
    raise "empty versions" unless versions
  end

  def validate_deployment_name
    user_defined_root_deployment_name = versions[ROOT_DEPLOYMENT_NAME] || versions[DEPRECATED_DEPLOYMENT_NAME]
    raise "invalid #{ROOT_DEPLOYMENT_NAME}" if user_defined_root_deployment_name.to_s.empty?
    raise "invalid/missing #{ROOT_DEPLOYMENT_NAME}: found #{user_defined_root_deployment_name} expected #{root_deployment_name}" if user_defined_root_deployment_name != root_deployment_name
  end

  def validate_stemcell_version
    raise "invalid/missing #{STEMCELL_VERSION}" if stemcell_version.to_s.empty?
  end

  def stemcell_version
    @versions.dig(STEMCELL, STEMCELL_VERSION)
  end
end
