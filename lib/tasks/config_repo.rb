module Tasks
  # Module to share ruby codes related to Config repository among concourse tasks
  module ConfigRepo
    require_relative './config_repo/deployments'
  end
end
