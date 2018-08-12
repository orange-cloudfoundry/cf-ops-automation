require_relative './bucc'
require_relative './errors'

module CoaEnvBootstrapper
  # This class serves as a adapter to communicate with whichever software
  # created the environment
  class EnvCreatorAdapter < Base
    attr_reader :adapter

    def initialize(adapter_name, prereqs)
      # NOTE: if more than 2 cases, think about using rails' ActiveSupport to
      # metaprogram the loading.
      # class_object = adapter_name.constantize; class_object.new(prereqs[adapter_name])
      @adapter =
        case adapter_name
        when "bucc" then Bucc.new(prereqs["bucc"])
        else
          message = "No adapter implemented for #{adapter_name}"
          logger.error message
          raise EnvCreatorAdapterNotImplementedError, message
        end
    end

    def deploy_transient_infra
      logger.log_and_puts :debug, 'Deploying transient infra source profile'
      adapter.deploy_transient_infra
    end

    def vars
      adapter.vars
    end

    def concourse_target
      adapter.concourse_target
    end

    def display_concourse_login_information
      puts "Your info to connect to Concourse:"
      adapter.display_concourse_login_information
    end
  end
end
