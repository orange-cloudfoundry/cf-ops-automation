require 'coa_env_bootstrapper/bucc'

module CoaEnvBootstrapper
  class EnvCreatorAdapter
    def initialize(coa_env_bootstrapper, adapter_name)
      @ceb = coa_env_bootstrapper
      if adapter_name == "bucc"
        @adapter = Bucc.new(@ceb)
      end
    end

    def deploy_transiant_infra
      @adapter.deploy_transiant_infra
    end

    def vars
      @adapter.vars
    end

    def concourse_target
      @adapter.concourse_target
    end
  end
end
