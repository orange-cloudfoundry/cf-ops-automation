require_relative 'deployment'
require_relative 'config'

class DeploymentFactory
  attr_reader :version_reference, :root_deployment_name, :config

  def initialize(root_deployment_name, version_reference = {}, config = Config.new)
    @version_reference = {}
    @version_reference = version_reference unless version_reference.nil?
    @config = config
    @root_deployment_name = root_deployment_name
    validate
  end

  def load_files(filename = '')
    deployment_dependencies_extension = File.extname(filename)
    deployment_dependencies_basename = filename.gsub(deployment_dependencies_extension, '')
    deployment_dependencies_loaded = load_file(filename)

    all_deployment_dependencies_loaded = load_and_merge(deployment_dependencies_basename, deployment_dependencies_loaded, @config.iaas_type(@root_deployment_name))
    profiles = @config.profiles(root_deployment_name)
    profiles.each do |profile|
      current_deployment_dependencies_loaded = all_deployment_dependencies_loaded
      all_deployment_dependencies_loaded = load_and_merge(deployment_dependencies_basename, current_deployment_dependencies_loaded, profile)
    end
    [update_bosh_options(all_deployment_dependencies_loaded.first)]
  end

  def load_file(filename = '')
    validate_file(filename)
    puts "DeploymentFactory - processing #{filename}"
    deployment_name = File.dirname(filename)&.split(File::SEPARATOR)&.last
    yaml_file = YAML.load_file(filename) || {}
    load(deployment_name, yaml_file)
  end

  def load(deployment_name = '', data = {})
    raise "invalid deployment_name. Cannot be empty" if deployment_name.empty?
    raise "invalid data. Cannot load empty data" if data.empty?

    deployment_info = load_deployment_info(data)
    process_deployment_info(deployment_info, deployment_name)
  end

  def stemcell_name
    @config.stemcell_name(@root_deployment_name)
  end

  def stemcell_version
    @version_reference.dig('stemcell', 'version')
  end

  private

  def load_and_merge(deployment_dependencies_basename, deployment_dependencies_loaded, suffix)
    iaas_filename = "#{deployment_dependencies_basename}-#{suffix}.yml"
    iaas_loaded = File.exist?(iaas_filename) ? load_file(iaas_filename) : [Deployment.new('empty-deployment')]
    puts "#{iaas_filename} content: #{iaas_loaded}"
    puts "deployment_dependencies_loaded content: #{deployment_dependencies_loaded}"
    merge(deployment_dependencies_loaded.first, iaas_loaded.first)
  end

  def validate_file(filename)
    raise 'invalid filename. Cannot be empty' if filename.to_s.empty?
    raise "file not found: #{filename}" unless File.exist?(filename)
  end

  def process_deployment_info(deployment_info, deployment_name)
    deployments = []
    deployment_info.each do |current_deployment_name, deployment_details|
      raise "Invalid deployment_name: expected <#{deployment_name}> or <bosh-deployment> - Found <#{current_deployment_name}> " unless deployment_name == current_deployment_name || current_deployment_name == 'bosh-deployment'

      update_deployment_details(deployment_details)
      deployments << Deployment.new(deployment_name, deployment_details)
    end
    deployments
  end

  def load_deployment_info(data)
    deployment_info = data['deployment'] || {}
    raise "Invalid data. Missing root: 'deployment'" if deployment_info.empty?

    deployment_info
  end

  def update_bosh_options(deployment)
    return deployment unless deployment

    deployment_details = deployment.details.dup
    return deployment unless deployment_details

    default_option = @config.bosh_options.dup || {}
    current_options = deployment_details.dig('bosh-options') || {}
    deployment_details['bosh-options'] = default_option.merge(current_options)
    Deployment.new(deployment.name, deployment_details)
  end

  def update_deployment_details(deployment_details)
    update_boshrelease_version(deployment_details)
    add_stemcell_info(deployment_details)
  end

  def add_stemcell_info(deployment_details)
    return if deployment_details.nil?

    deployment_details['stemcells'] = { stemcell_name => {} } unless deployment_details['stemcells']
  end

  def update_boshrelease_version(deployment_details)
    return if deployment_details.nil?

    boshrelease_list = deployment_details['releases']
    boshrelease_list&.each do |a_release, _|
      version = @version_reference.dig('releases', a_release, 'version')
      raise "Missing boshrelease version: expecting 'releases.#{a_release}.version' key in #{@root_deployment_name}/root-deployment.yml. Data: #{@version_reference['releases']}" if version.nil?

      current_release = deployment_details['releases'][a_release] || {}
      current_release['version'] = version
      deployment_details['releases'][a_release] = current_release
    end
  end

  def merge(initial, override)
    [initial.merge(override)]
  end

  def validate
    raise 'invalid/missing root_deployment_name' if @root_deployment_name.nil? || @root_deployment_name.empty?

    validate_config
    validate_version_reference
  end

  def validate_config
    raise 'invalid config: cannot be nil' if @config.nil?
    raise 'invalid config: missing stemcell, expected: a config with a stemcell name defined' if @config.stemcell_name(@root_deployment_name).to_s.empty?
  end

  def validate_version_reference
    raise 'invalid version: missing stemcell version' if @version_reference.dig('stemcell', 'version').to_s.empty?
  end
end
