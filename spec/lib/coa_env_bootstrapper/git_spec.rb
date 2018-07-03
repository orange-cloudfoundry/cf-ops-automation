require 'spec_helper'
require 'coa_env_bootstrapper/git'

describe CoaEnvBootstrapper::Git do
  describe '.new'
  describe '#prepare_environment'
  describe '#push_templates_repo'
  describe '#push_secrets_repo'
  describe '#download_git_dependencies'
  describe '#server_ip'
end
