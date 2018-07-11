require 'yaml'
require_relative './command_runner'
require_relative './errors'

module CoaEnvBootstrapper
  # Manage BUCC deployment
  class Bucc
    include CommandRunner
    attr_reader :prereqs

    def initialize(prereqs)
      @prereqs = prereqs || {}
    end

    def deploy_transient_infra
      run_cmd "#{bucc_cli_path} up --cpi #{prereqs['cpi']} \
#{prereqs['cpi_specific_options']} --lite --debug"
    end

    def vars
      @vars ||=
        begin
          command_result = run_cmd("#{bucc_cli_path} vars")
          YAML.safe_load(command_result)
        rescue ::Errno::ENOENT => error
          raise BuccCommandError, "You may be missing bucc in your $PATH. Error:\n#{error.message}"
        rescue ::Psych::SyntaxError => error
          raise BuccCommandError, "Cannot load vars from `bucc vars` command. Error:\n#{error.message}"
        end
    end

    def bucc_cli_path
      "#{prereqs['bin_path']}/bucc"
    end

    def concourse_target
      "bucc"
    end

    def display_concourse_login_information
      run_cmd "#{bucc_cli_path} info"
    end
  end
end
