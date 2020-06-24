# Module to share ruby codes among concourse tasks
module Tasks
  require_relative './tasks/bosh'
  require_relative './tasks/config_repo'
  require_relative './tasks/templates_repo'

  # Class to hold invalid task parameter error
  class InvalidTaskParameter < RuntimeError; end
end
