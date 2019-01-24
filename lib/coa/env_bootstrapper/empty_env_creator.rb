require 'yaml'
require_relative './base'

module Coa
  module EnvBootstrapper
    # This class manages BUCC deployment and can provide `bucc vars`
    class EmptyEnvCreator < Base
      def deploy_transient_infra
        raise EnvCreatorAdapterNotImplementedError,
              "Cannot deploy the transient infrastructure unless a proper env creator, such as bucc, is set."
      end

      def vars
        {}
      end
    end
  end
end
