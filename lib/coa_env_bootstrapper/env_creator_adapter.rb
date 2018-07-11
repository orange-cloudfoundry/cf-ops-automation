require_relative './bucc'
require_relative './errors'

module CoaEnvBootstrapper
  class EnvCreatorAdapter
    attr_reader :adapter

    def initialize(adapter_name, prereqs)
      # NOTE: if more than 2 cases, think about using rails' ActiveSupport to
      # metaprogram the loading.
      # class_object = adapter_name.constantize; class_object.new(prereqs[adapter_name])
      @adapter =
        case adapter_name
        when "bucc" then Bucc.new(prereqs["bucc"])
        else raise EnvCreatorAdapterNotImplementedError, "No adapter implemented for #{adapter_name}"
        end
    end

    def deploy_transient_infra
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
