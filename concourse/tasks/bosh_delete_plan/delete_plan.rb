require 'json'

# Monkey patch String class to write using a few colors
class String
  def black
    "\e[30m#{self}\e[0m"
  end

  def red
    "\e[31m#{self}\e[0m"
  end

  def green
    "\e[32m#{self}\e[0m"
  end
end

# This class is a dry run before effectively removing bosh deployments or directory.
class DeletePlan
  def initialize(bosh_command_holder = Tasks::Bosh::ListDeployments.new, config_repo_deployments = Tasks::ConfigRepo::Deployments.new)
    @list_command_holder = bosh_command_holder
    @config_repo_deployments = config_repo_deployments
  end

  def process
    deployments_file = ENV.fetch('OUTPUT_FILE', File.join('deployments-to-delete', 'file.txt'))

    expected_deployments = @config_repo_deployments.enabled_deployments
    puts "Expected deployments detected: #{expected_deployments}"
    protected_deployments = @config_repo_deployments.protected_deployments
    puts "Protected deployments detected: #{protected_deployments}"

    deployed_bosh_deployments = @list_command_holder.execute
    puts "Active bosh deployments: #{deployed_bosh_deployments}"
    puts "Filtering deployments (ie: excluding expected and protected deployments)"
    deployed_bosh_deployments.delete_if { |deployment_name| expected_deployments&.include?(deployment_name) || protected_deployments&.include?(deployment_name) }

    deployed_bosh_deployments.each do |name|
      display_inactive_message(name)
      append_deployment_name_to_file(name, deployments_file)
    end
    @config_repo_deployments.cleanup_disabled_deployments
  end

  private

  def append_deployment_name_to_file(name, deployments_file)
    File.open(deployments_file, 'a') { |file| file.puts name.to_s }
  end

  def display_inactive_message(name)
    puts "#{name.red} deployment has been detected as 'inactive', ie :\n" \
      "\t  - paas-template contains deployment descriptors\n" \
      "\t  - secrets does not enable this deployment\n" \
      "\t  - deployment secrets dir does not contain 'protect-deployment.yml' mark to skip deletion\n" \
      "\tThis bosh deployment is going to be deleted on bosh, and files removed in secrets ('#{name}.yml', '#{name}-fingerprint.yml' and '#{name}-last-deployment-failure.yml').\n" \
      "\t! Waiting for manual approval !\n" \
      ''
  end
end
