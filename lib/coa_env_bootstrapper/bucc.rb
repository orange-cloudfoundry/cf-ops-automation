require 'yaml'
require_relative './command_runner'
require_relative './errors'

module CoaEnvBootstrapper
  class Bucc
    include CommandRunner
    attr_reader :prereqs

    def initialize(prereqs)
      @prereqs = prereqs || {}
    end

    def deploy_transiant_infra
      run_cmd "bucc up --cpi #{prereqs["cpi"]} \
#{prereqs["cpi_specific_options"]} --lite --debug"
    end

    def vars
      @vars ||=
        begin
          command_result = run_cmd("bucc vars")
          YAML.safe_load(command_result)
        rescue ::Psych::SyntaxError => error
          raise BuccCommandError, "Cannot load vars from `bucc vars` command. Result: #{error.message}"
        end
    end

    def concourse_target
      "bucc"
    end

    def display_concourse_login_information
      run_cmd "bucc info"
    end
  end
end
