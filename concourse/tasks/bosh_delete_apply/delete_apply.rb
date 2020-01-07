require 'json'

# This class is remove unwanted bosh deployments or directory.
class DeleteApply
  def initialize(list_command = Tasks::Bosh::ListDeployments.new, delete_command = Tasks::Bosh::DeleteDeployment.new, config_repo_deployments = Tasks::ConfigRepo::Deployments.new('output-config-resource'))
    @list_command_holder = list_command
    @delete_command_holder = delete_command
    @config_repo_deployments = config_repo_deployments
  end

  def process
    expected_deployments = @config_repo_deployments.enabled_deployments
    puts "Expected deployments: #{expected_deployments}"
    protected_deployments = @config_repo_deployments.protected_deployments
    puts "Protected deployments: #{protected_deployments}"

    deployed_bosh_deployments = @list_command_holder.execute
    puts "Active bosh deployments: #{deployed_bosh_deployments}"
    puts "Filtering deployments (ie: excluding expected and protected deployments)"
    deployed_bosh_deployments.delete_if { |deployment_name| expected_deployments&.include?(deployment_name) || protected_deployments&.include?(deployment_name) }

    puts "Deployments to delete: #{deployed_bosh_deployments}"
    deployed_bosh_deployments.each do |deployment_name|
      @delete_command_holder.execute(deployment_name)
      @config_repo_deployments.cleanup_deployment(deployment_name)
    end
    @config_repo_deployments.cleanup_disabled_deployments
  end
end
