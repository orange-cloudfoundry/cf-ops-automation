require_relative './base'

module Coa
  module EnvBootstrapper
    # Manage interaction with Credhub prerequisites during bootstrap
    class Credhub < Coa::EnvBootstrapper::Base
      attr_reader :config

      COA_CONFIG_DIR = "#{SECRETS_REPO_DIR}/coa/config".freeze
      CREDHUB_CREDENTIALS_FILENAME = "#{COA_CONFIG_DIR}/credentials-credhub-created-by-ITs.yml".freeze

      def initialize(config)
        @config = config
        validate_credhub_config
      end

      def prepare_environment
        logger.log_and_puts :debug, 'Preparing Credhub environment (i.e: secrets)'
        puts CREDHUB_CREDENTIALS_FILENAME
        generate_credentials_file
      end

      private

      def validate_credhub_config
        raise NoActiveStepConfigError.new('credhub.server', 'transform_config_into_credentials') if credhub_config.dig('server').to_s.empty?
        raise NoActiveStepConfigError.new('credhub.client', 'transform_config_into_credentials') if credhub_config.dig('client').to_s.empty?
        raise NoActiveStepConfigError.new('credhub.secret', 'transform_config_into_credentials') if credhub_config.dig('secret').to_s.empty?
      end

      def credhub_config
        @config&.credhub
      end

      def generate_credentials_file
        raise NoActiveStepConfigError.new('credhub', 'generate_credentials_file') unless credhub_config

        credentials = transform_config_into_credentials
        FileUtils.mkdir_p(COA_CONFIG_DIR)
        write_credentials_file(credentials)
      end

      def transform_config_into_credentials
        {
          'credhub-server' => credhub_config.dig('server'),
          'credhub-client' => credhub_config.dig('client'),
          'credhub-secret' => credhub_config.dig('secret')
        }
      end

      def write_credentials_file(content)
        File.open(CREDHUB_CREDENTIALS_FILENAME, 'w') { |file| file.write(content.to_yaml) }
      end
    end
  end
end
