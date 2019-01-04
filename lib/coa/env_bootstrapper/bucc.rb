require 'yaml'
require_relative './base'
require_relative './errors'
require_relative '../constants'

module Coa
  module EnvBootstrapper
    # This class manages BUCC deployment and can provide `bucc vars`
    class Bucc < Base
      include Constants

      attr_reader :prereqs

      def initialize(prereqs)
        @prereqs = prereqs
      end

      # NOTE: the presence of a state.json file in the bucc repo leads bucc
      # to believe that the VM is up even when it's not.
      def deploy_transient_infra
        run_cmd "#{bucc_cli_path} up --cpi #{prereqs['cpi']} \
#{prereqs['cpi_specific_options']} --lite --debug"
      end

      def in_use?
        prereqs == {}
      end

      def vars
        @vars ||=
          begin
            command_result = run_cmd("#{bucc_cli_path} vars", verbose: false)
            YAML.safe_load(command_result)
          rescue ::Errno::ENOENT => error
            raise BuccCommandError, "You may be missing bucc in your $PATH. Error:\n#{error.message}"
          rescue ::Psych::SyntaxError => error
            raise BuccCommandError, "Cannot load vars from `bucc vars` command. Error:\n#{error.message}"
          end
      end

      def bucc_cli_path
        "#{PROJECT_ROOT_DIR}/bin/bucc/bin/bucc"
      end

      def concourse_target
        "bucc"
      end

      def display_concourse_login_information
        run_cmd "#{bucc_cli_path} info"
      end
    end
  end
end
