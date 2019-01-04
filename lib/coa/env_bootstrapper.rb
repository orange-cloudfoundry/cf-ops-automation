module Coa
  # This module helps bootstrapping a new COA environment from scratch
  module EnvBootstrapper
    require_relative './env_bootstrapper/bosh'
    require_relative './env_bootstrapper/bucc'
    require_relative './env_bootstrapper/concourse'
    require_relative './env_bootstrapper/git'
    require_relative './env_bootstrapper/runner'
  end
end
