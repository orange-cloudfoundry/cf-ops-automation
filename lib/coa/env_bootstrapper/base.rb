require 'pathname'
require_relative '../constants'
require_relative '../utils/coa_logger'
require_relative '../utils/command_runner'

module Coa
  module EnvBootstrapper
    # This class serves as a base class for other classes of the module
    class Base
      include Coa::Utils::CoaLogger
      include Coa::Constants

      OUTPUT_DIR_NAME    = 'output_dir'.freeze
      SECRETS_REPO_DIR   = "#{PROJECT_ROOT_DIR}/docs/reference_dataset/config_repository".freeze
      TEMPLATES_REPO_DIR = "#{PROJECT_ROOT_DIR}/docs/reference_dataset/template_repository".freeze
      K8S_CONFIGS_REPO_DIR = "#{PROJECT_ROOT_DIR}/docs/reference_dataset/k8s_configs_repository".freeze
      AUDIT_TRAIL_REPO_DIR = "#{PROJECT_ROOT_DIR}/docs/reference_dataset/concourse_audit_trail_repository".freeze

      def run_cmd(command, options = {})
        Coa::Utils::CommandRunner.new(command, options).execute
      end
    end
  end
end
