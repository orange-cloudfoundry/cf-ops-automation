module Tasks
  # Module to share ruby codes related to bosh CLI among concourse tasks
  module Bosh
    require_relative './bosh/executor'
    require_relative './bosh/list_deployments'
    require_relative './bosh/delete_deployment'
    require_relative './bosh/cancel_task'
    require_relative './bosh/list_tasks'
    require_relative './bosh/list_releases'
    require_relative './bosh/create_release'
  end
end
