module CoaEnvBootstrapper
  class BuccCommandError < StandardError; end
  class EnvCreatorAdapterNotImplementedError < StandardError; end
  class ConfigDirNotFound < StandardError
    def initialize(msg = "Tmp config dir for Bootstrapper not found.")
      super
    end
  end
end
