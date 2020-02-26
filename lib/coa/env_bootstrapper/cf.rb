require_relative './base'
require_relative '../utils/cf'

module Coa
  module EnvBootstrapper
    # Manage interaction with Cloudfoundry prerequisites during bootstrap
    class Cf < Coa::EnvBootstrapper::Base
      attr_reader :config

      CF_APPLICATIONS_PATH = "#{SECRETS_REPO_DIR}/hello-world-root-depls/cf-apps-deployments".freeze
      CF_APPLICATION_ACTIVATION_FILENAME = "enable-cf-app.yml".freeze

      def initialize(config)
        @config = config
      end

      def prepare_environment(prereqs)
        logger.log_and_puts :debug, 'Preparing CF environment'
        generate_activation_files(prereqs.cf)
      end

      def generate_activation_files(cf_config)
        raise NoActiveStepConfigError.new('cf', 'generate_activation_files') unless cf_config

        application_name = 'generic-app'
        enable_cf_app_file = File.join(CF_APPLICATIONS_PATH, application_name, CF_APPLICATION_ACTIVATION_FILENAME)
        file_content = create_enable_cf_app_content(cf_config, application_name)
        file = File.open(enable_cf_app_file, 'w')
        file.write(file_content.to_yaml)
        file.close
      end

      private

      def create_enable_cf_app_content(cf_config, app_name)
        cf_coa_config = Coa::Utils::Cf::Config.new(cf_config)
        { 'cf-app' => { app_name => cf_coa_config.to_h } }
      end
    end
  end
end
