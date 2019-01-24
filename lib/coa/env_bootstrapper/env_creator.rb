require_relative './bucc'
require_relative './empty_env_creator'
require_relative './errors'
require_relative './prereqs'

module Coa
  module EnvBootstrapper
    # This class serves as a adapter to communicate with whichever software
    # created the environment
    class EnvCreator < Base
      attr_reader :adapter

      def initialize(prereqs = Coa::EnvBootstrapper::Prereqs.new)
        @adapter = prereqs.bucc ? Coa::EnvBootstrapper::Bucc.new(prereqs.bucc) : Coa::EnvBootstrapper::EmptyEnvCreator.new
      end

      def deploy_transient_infra
        adapter.deploy_transient_infra
      end

      def vars
        adapter.vars
      end
    end
  end
end
