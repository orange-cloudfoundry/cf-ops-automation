require 'yaml'
require 'tempfile'
require 'pathname'
require 'open3'

module CoaEnvBootstrapper
  require_relative './coa_env_bootstrapper/base'
  require_relative './coa_env_bootstrapper/bosh'
  require_relative './coa_env_bootstrapper/concourse'
  require_relative './coa_env_bootstrapper/git'

  PROJECT_ROOT_DIR = Pathname.new(File.dirname(__FILE__) + '/..').realdirpath
  SOURCE_FILE_NAME = 'source'
  OUTPUT_DIR_NAME = 'output_dir'
end
