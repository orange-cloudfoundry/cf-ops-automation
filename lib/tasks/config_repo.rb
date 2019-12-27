module Tasks
  # Module to share ruby codes related to bosh CLI among concourse tasks
  module ConfigRepo
    require_relative './config_repo/deployments'
  end
end
