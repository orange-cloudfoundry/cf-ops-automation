# Bootstrap a new COA environment from scratch
module CoaEnvBootstrapper
  require_relative './coa_env_bootstrapper/bosh'
  require_relative './coa_env_bootstrapper/bucc'
  require_relative './coa_env_bootstrapper/concourse'
  require_relative './coa_env_bootstrapper/git'
  require_relative './coa_env_bootstrapper/runner'
end
