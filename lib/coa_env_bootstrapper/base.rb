require 'pathname'
require_relative '../concerns/coa_logger'
require_relative '../concerns/coa_command_runner'

module CoaEnvBootstrapper
  class Base
    include CoaLogger

    PROJECT_ROOT_DIR   = Pathname.new(File.dirname(__FILE__) + '/../..').realdirpath
    OUTPUT_DIR_NAME    = 'output_dir'.freeze
    SECRETS_REPO_DIR   = "#{PROJECT_ROOT_DIR}/docs/reference_dataset/config_repository".freeze
    TEMPLATES_REPO_DIR = "#{PROJECT_ROOT_DIR}/docs/reference_dataset/template_repository".freeze

    def extract_from_prereqs(prereqs, prereqs_key, additional_info = {})
      keys_prereqs = prereqs[prereqs_key] || {}
      keys_prereqs&.merge(additional_info) || {}
    end

    def run_cmd(command, options = {})
      CoaCommandRunner.new(command, options).execute
    end
  end
end
