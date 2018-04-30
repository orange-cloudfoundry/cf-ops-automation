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

  def load_file(filename)
    raise 'invalid filename. Cannot be nil' if filename.nil?
    raise "file not found: #{filename}" unless File.exist?(filename)
    puts "processing #{filename}"
    yaml_file = YAML.load_file(filename) || {}
    load(yaml_file)
  end

  def load(data = {})
    raise "invalid data. Cannot load 'nil' data" if data.nil?
    deployments = []
    data['deployment']&.each do |deployment_name, deployment_details|
      update_deployment_details(deployment_details)
      deployments << Deployment.new(deployment_name, deployment_details)
    end
    raise "Invalid data. Missing root: 'deployment' or '<deployment_name>'" if deployments.empty?
    deployments
  end

  def update_deployment_details(deployment_details)
    update_boshrelease_version(deployment_details)
    add_stemcell_info(deployment_details)
  end

  def stemcell_name
    @config.stemcell_name
  end

  def stemcell_version
    @version_reference['stemcell-version']
  end

  private

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
