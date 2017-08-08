require_relative 'deployment'

class DeploymentFactory
  attr_reader :version_reference


  DEPLOYMENT_NAME='deployment-name'
  STEMCELL_VERSION='stemcell-version'
  STEMCELL_NAME='stemcell-name'

  def initialize(root_deployment_name, version_reference = {})
    @version_reference = version_reference
    @root_deployment_name = root_deployment_name
    validate
  end

  def load_file(filename)
    current_dependencies = YAML.load_file(filename)
    load(current_dependencies)
  end

  def load(data = {})
    deployments = []
    data['deployment'].each do |deployment_name, deployment_details|
      boshrelease_list = deployment_details['releases']
      boshrelease_list&.each do |a_release, _|
        version = version_reference[a_release + '-version']
        deployment_details['releases'][a_release]['version'] = version
      end
      deployment_details['stemcells'].each do |a_stemcell, _|
        raise "Invalid stemcell: expected <#{@version_reference['stemcells-name']}> - Found <#{a_stemcell}>" if a_stemcell != @version_reference['stemcell-name']

        version = @version_reference['stemcell-version']

        deployments << Deployment.new(deployment_name, deployment_details)
      end
    end
    raise "Invalid data. Missing root: 'deployment'" if deployments.empty?
    deployments
  end

  private

  def validate
    raise "invalid/missing #{DEPLOYMENT_NAME}" if @root_deployment_name.nil? || @root_deployment_name.empty?
    raise "invalid/missing #{DEPLOYMENT_NAME}" unless @version_reference[DEPLOYMENT_NAME] = @root_deployment_name
    raise "invalid/missing #{STEMCELL_VERSION}" if @version_reference[STEMCELL_VERSION].nil? #|| @version_reference[STEMCELL_VERSION].empty?
    raise "invalid/missing #{STEMCELL_NAME}" if @version_reference[STEMCELL_NAME].nil? || @version_reference[STEMCELL_NAME].empty?
  end


end