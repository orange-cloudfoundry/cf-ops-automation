module PipelineHelpers
  DEFAULT_BOSH_CLI_VERSION_VALUE = 'v2'.freeze
  DEFAULT_LOCAL_DEPLOYMENT_SCAN_VALUE = false
  DEFAULT_LOCAL_DEPLOYMENT_TRIGGER_VALUE = true
  DEFAULT_EMPTY_ERRANDS_VALUE = {}.freeze
  DEFAULT_EMPTY_RELEASES_VALUE = {}.freeze

  # this class helps parsing, and setting default values for deployments dependencies details instead of doing it in pipeline templates
  class DeploymentDetails
    attr_reader :config, :root_deployment_name

    def initialize(raw_details = {})
      @details = {}
      @details = raw_details if raw_details
    end

    def bosh_cli_version
      @details["cli_version"] || DEFAULT_BOSH_CLI_VERSION_VALUE
    end

    def local_deployment_secrets_scan?
      resources = @details["resources"]
      secrets_options = resources&.fetch("secrets", nil)
      if secrets_options
        secrets_options.fetch("local_deployment_scan", DEFAULT_LOCAL_DEPLOYMENT_SCAN_VALUE)
      else
        DEFAULT_LOCAL_DEPLOYMENT_SCAN_VALUE
      end
    end

    def local_deployment_secrets_trigger?
      resources = @details["resources"]
      secrets_options = resources&.fetch("secrets", nil)
      if secrets_options
        secrets_options.fetch("local_deployment_trigger", DEFAULT_LOCAL_DEPLOYMENT_TRIGGER_VALUE)
      else
        DEFAULT_LOCAL_DEPLOYMENT_TRIGGER_VALUE
      end
    end

    def errands?
      @details['errands']&.any?
    end

    def errands
      @details['errands'] || DEFAULT_EMPTY_ERRANDS_VALUE
    end

    def manual_errands?
      @details['manual-errands']&.any?
    end

    def manual_errands
      @details['manual-errands'] || DEFAULT_EMPTY_ERRANDS_VALUE
    end

    def releases
      @details['releases']&.sort || DEFAULT_EMPTY_RELEASES_VALUE
    end

    def select_secrets_scan_repository(on_local_scan, otherwise)
      if local_deployment_secrets_scan?
        on_local_scan
      else
        otherwise
      end
    end
  end
end
