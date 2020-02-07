require_relative 'deployment_factory'

#
# This class creates a list of deployer used by a deployment
class DeploymentDeployersConfig
  attr_reader :deployment_name, :public_base_location, :private_base_location

  DEPLOYMENT_DEPENDENCIES_FILENAME = 'deployment-dependencies.yml'.freeze
  CONCOURSE_CONFIG_DIRNAME = 'concourse-pipeline-config'.freeze
  TERRAFORM_CONFIG_DIRNAME = 'terraform-config'.freeze
  KUBERNETES_CONFIG_DIRNAME = 'kubernetes-config'.freeze
  BOSH_DEPLOYMENT_CONFIG_DIRNAME = 'bosh-deployment-config'.freeze
  OLD_BOSH_DEPLOYMENT_CONFIG_DIRNAME = 'template'.freeze
  BOSH_DIRECTOR_CONFIG_DIRNAME = 'bosh-director-config'.freeze

  def initialize(deployment_name, public_base_location, private_base_location, deployment_factory)
    @deployment_name = deployment_name
    @public_base_location = public_base_location
    @private_base_location = private_base_location
    @deployment_factory = deployment_factory
  end

  def load_configs
    deployment_details = {}
    load_bosh_config(deployment_details)
    load_terraform_config(deployment_details)
    load_concourse_config(deployment_details)
    load_kubernetes_config(deployment_details)
    raise "Inconsistency detected: deployment <#{@deployment_name}> is marked as active, but no #{DEPLOYMENT_DEPENDENCIES_FILENAME}, nor other deployer config found at #{@public_base_location}" if deployment_details.empty?

    create_and_enable_deployment(deployment_details)
  end

  private

  def create_and_enable_deployment(deployment_details)
    Deployment.new(@deployment_name, deployment_details).enable
  end

  def load_bosh_config(deployment_details)
    puts "Bosh release detected: #{@deployment_name}"
    dependency_filename = File.join(@public_base_location, DEPLOYMENT_DEPENDENCIES_FILENAME)
    return unless File.exist?(dependency_filename)

    @deployment_factory&.load_files(dependency_filename)&.each do |deployment|
      raise "#{@private_base_location} - Invalid deployment: expected <#{@deployment_name}> - Found <#{deployment.name}>" if deployment.name != @deployment_name

      deployment_details.merge! deployment.details
    end
    deployment_details['bosh-deployment'] = activate if exist_bosh_config_dir?
  end

  def exist_bosh_config_dir?
    template_dir_detected = Dir.exist?(File.join(@public_base_location, OLD_BOSH_DEPLOYMENT_CONFIG_DIRNAME))
    bosh_deployment_dir_detected = Dir.exist?(File.join(@public_base_location, BOSH_DEPLOYMENT_CONFIG_DIRNAME))
    bosh_deployment_dir_detected || template_dir_detected
  end

  def load_kubernetes_config(deployment_details)
    deployment_details['kubernetes'] = activate if Dir.exist? File.join(@public_base_location, KUBERNETES_CONFIG_DIRNAME)
  end

  def load_concourse_config(deployment_details)
    deployment_details['concourse'] = activate if Dir.exist? File.join(@public_base_location, CONCOURSE_CONFIG_DIRNAME)
  end

  def load_terraform_config(deployment_details)
    deployment_details['terraform'] = activate if Dir.exist? File.join(@public_base_location, TERRAFORM_CONFIG_DIRNAME)
  end

  def activate
    { 'active' => true }
  end
end
