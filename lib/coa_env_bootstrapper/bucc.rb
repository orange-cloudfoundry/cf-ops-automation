module CoaEnvBootstrapper
  class Bucc
    attr_reader :ceb

    def initialize(coa_env_bootstrapper)
      @ceb = coa_env_bootstrapper
    end

    def deploy_transiant_infra
      bucc_prereqs = ceb.prereqs["bucc"]
      run_cmd "bucc up --cpi #{ceb.bucc_prereqs["cpi"]} \
#{bucc_prereqs["cpi_specific_options"]} --lite --debug"
    end

    def vars
      @vars ||= YAML.safe_load(run_cmd("bucc vars"))
    end

    def concourse_target
      "bucc"
    end
  end
end
