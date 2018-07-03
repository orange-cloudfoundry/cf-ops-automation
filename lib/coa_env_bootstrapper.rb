require 'yaml'
require 'tempfile'
require 'pathname'
require 'open3'

module CoaEnvBootstrapper
  PROJECT_ROOT_DIR = Pathname.new(File.dirname(__FILE__) + '/..').realdirpath
  SOURCE_FILE_NAME = 'source'
  OUTPUT_DIR_NAME = 'output_dir'
end
