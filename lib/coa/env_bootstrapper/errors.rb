require_relative '../utils/coa_logger'

module Coa
  module EnvBootstrapper
    # Error raised by BUCC
    class BuccCommandError < StandardError
      include Coa::Utils::CoaLogger
      def initialize(msg)
        logger.error(msg)
        super
      end
    end

    # Error raised when no EnvCreatorAdapater is found
    class EnvCreatorAdapterNotImplementedError < StandardError; end

    # Error raised when the config for an active step is missing
    class NoActiveStepConfigError < StandardError
      include Coa::Utils::CoaLogger
      def initialize(config_key, step)
        msg = "No '#{config_key}' config provided in the prerequisites but step '#{step}' active."
        logger.log_and_puts :error, msg
        super(msg)
      end
    end
  end
end
