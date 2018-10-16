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
    validate_config
    validate_version_reference
  end

  def load_file_with_iaas(filename = '')
    deployment_dependencies_extension = File.extname(filename)
    deployment_dependencies_basename = filename.gsub(deployment_dependencies_extension, '')
    deployment_dependencies_loaded = load_file(filename)

    iaas_filename = "#{deployment_dependencies_basename}-#{@config.iaas_type}.yml"
    iaas_loaded = File.exist?(iaas_filename) ? load_file(iaas_filename) : [Deployment.new('empty-deployment')]
    puts "#{iaas_filename} content: #{iaas_loaded}"
    merge(deployment_dependencies_loaded.first, iaas_loaded.first)
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
    @config.stemcell_name
  end

  def stemcell_version
    @version_reference['stemcell-version']
  end

  private

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

  def update_deployment_details(deployment_details)
    update_boshrelease_version(deployment_details)
    add_stemcell_info(deployment_details)
  end

  def add_stemcell_info(deployment_details)
    return if deployment_details.nil?
    deployment_details['stemcells'] = { stemcell_name => {} }
  end

  def update_boshrelease_version(deployment_details)
    return if deployment_details.nil?
    boshrelease_list = deployment_details['releases']
    boshrelease_list&.each do |a_release, _|
      version = version_reference[a_release + '-version']
      raise "Missing boshrelease version: expecting '#{a_release}-version' key in #{@root_deployment_name}-versions.yml" if version.nil?
      deployment_details['releases'][a_release]['version'] = version
    end
  end

  def merge(initial, override)
    [initial.merge(override)]
  end

  def validate
    raise 'invalid/missing root_deployment_name' if @root_deployment_name.nil? || @root_deployment_name.empty?
  end

  def validate_config
    raise 'invalid config: cannot be nil' if @config.nil?
    raise 'invalid config: missing stemcell, expected: a config with a stemcell name defined' if @config.stemcell_name.to_s.empty?
  end

  def validate_version_reference
    raise 'invalid version: missing stemcell version' if @version_reference['stemcell-version'].to_s.empty?
  end
end
