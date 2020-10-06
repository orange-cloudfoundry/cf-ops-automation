module Coa
  # This module helps bootstrapping a new COA environment from scratch
  module EnvBootstrapper
    require_relative './env_bootstrapper/bootstrapper'
    require_relative './env_bootstrapper/bosh'
    require_relative './env_bootstrapper/bucc'
    require_relative './env_bootstrapper/concourse'
    require_relative './env_bootstrapper/empty_env_creator'
    require_relative './env_bootstrapper/env_creator'
    require_relative './env_bootstrapper/errors'
    require_relative './env_bootstrapper/git'
    require_relative './env_bootstrapper/prereqs'
    require_relative './env_bootstrapper/credhub'
  end
end
