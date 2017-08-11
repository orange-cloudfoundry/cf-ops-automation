require_relative 'deployment'

class DeploymentFactory
  attr_reader :version_reference, :root_deployment_name

  def initialize(root_deployment_name, version_reference = {})
    @version_reference = version_reference
    @root_deployment_name = root_deployment_name
    validate
  end

  def load_file(filename)
    raise "file not found: #{filename}" unless File.exist?(filename)
    load(YAML.load_file(filename))
  end

  def load(data = {})
    deployments = []
    data['deployment'].each do |deployment_name, deployment_details|
      update_deployment_version!(deployment_details)
      deployments << Deployment.new(deployment_name, deployment_details)
    end
    raise "Invalid data. Missing root: 'deployment'" if deployments.empty?
    deployments
  end

  def update_deployment_version!(deployment_details)
    update_boshrelease_version!(deployment_details)
    update_stemcell_version!(deployment_details)
  end


  private

  def update_stemcell_version!(deployment_details)
    deployment_details['stemcells'].each do |a_stemcell, _|
      raise "Invalid stemcell: expected <#{@version_reference['stemcells-name']}> - Found <#{a_stemcell}>" if a_stemcell != @version_reference['stemcell-name']
      version = @version_reference['stemcell-version']
    end
  end

  def update_boshrelease_version!(deployment_details)
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

end