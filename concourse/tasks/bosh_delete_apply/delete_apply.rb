require 'json'

# This class is remove unwanted bosh deployments or directory.
class DeleteApply
  def initialize(list_command = Tasks::Bosh::ListDeployments.new, delete_command = Tasks::Bosh::DeleteDeployment.new, config_repo_deployments = Tasks::ConfigRepo::Deployments.new('output-config-resource'))
    @list_command_holder = list_command
    @delete_command_holder = delete_command
    @config_repo_deployments = config_repo_deployments
  end

  def process
    deployed_bosh_deployments = filter_deployment_to_delete

    deployment_deletion_failure = delete_deployments(deployed_bosh_deployments)
    if deployment_deletion_failure.empty?
      @config_repo_deployments.cleanup_disabled_deployments
    else
      deployment_deletion_failure.each { |deployment_name, error| puts "Error deleting #{deployment_name}: #{error}" }
      raise Tasks::Bosh::BoshCliError, "Failed to delete deployments: #{deployment_deletion_failure.keys}"
    end
  end

  private

  def delete_deployments(deployed_bosh_deployments)
    puts "Deployments to delete: #{deployed_bosh_deployments}"
    deployment_deletion_failure = {}
    deployed_bosh_deployments.each do |deployment_name|
      delete_deployment(deployment_deletion_failure, deployment_name)
    end
    deployment_deletion_failure
  end

  def filter_deployment_to_delete
    expected_deployments = @config_repo_deployments.enabled_deployments
    puts "Expected deployments: #{expected_deployments}"
    protected_deployments = @config_repo_deployments.protected_deployments
    puts "Protected deployments: #{protected_deployments}"

    deployed_bosh_deployments = @list_command_holder.execute
    puts "Active bosh deployments: #{deployed_bosh_deployments}"
    puts "Filtering deployments (ie: excluding expected and protected deployments)"
    deployed_bosh_deployments.delete_if { |deployment_name| expected_deployments&.include?(deployment_name) || protected_deployments&.include?(deployment_name) }
    deployed_bosh_deployments
  end

  def delete_deployment(deployment_deletion_failure, deployment_name)
    @delete_command_holder.execute(deployment_name)
    @config_repo_deployments.cleanup_deployment(deployment_name)
  rescue Tasks::Bosh::BoshCliError => e
    deployment_deletion_failure[deployment_name] = e
  end
end
