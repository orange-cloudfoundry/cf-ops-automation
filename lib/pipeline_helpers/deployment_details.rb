module PipelineHelpers
  DEFAULT_BOSH_CLI_VERSION_VALUE = 'v2'.freeze
  DEFAULT_LOCAL_DEPLOYMENT_SCAN_VALUE = false
  DEFAULT_LOCAL_DEPLOYMENT_TRIGGER_VALUE = true
  DEFAULT_EMPTY_ERRANDS_VALUE = {}.freeze
  DEFAULT_EMPTY_RELEASES_VALUE = {}.freeze

  # this class helps parsing, and setting default values for deployments dependencies details instead of doing it in pipeline templates
  class DeploymentDetails
    attr_reader :config, :deployment_name, :bosh_details, :git_details

    def initialize(deployment_name, raw_details = {})
      @details = raw_details || {}
      @deployment_name = deployment_name
      @bosh_details = BoshDeploymentDetails.new(deployment_name, @details.dig('bosh-options'))
      @git_details = GitDeploymentDetails.new(deployment_name, @details.dig('git-options'))
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

  class BoshDeploymentDetails
    attr_reader :deployment_name, :skip_drain, :max_in_flight

    # Values from https://github.com/cloudfoundry/bosh-deployment-resource/#out-deploy-or-delete-a-bosh-deployment-defaults-to-deploy
    # cleanup: Optional. An boolean that specifies if a bosh cleanup should be run after deployment. Defaults to false.
    # no_redact: Optional. Removes redacted from Bosh output. Defaults to false.
    # dry_run: Optional. Shows the deployment diff without running a deploy. Defaults to false.
    # fix: Optional. Recreate an instance with an unresponsive agent instead of erroring. Defaults to false.
    # max_in_flight: Optional. A number of max in flight option.
    # recreate: Optional. Recreate all VMs in deployment. Defaults to false.
    # skip_drain: Optional. A collection of instance group names to skip running drain scripts for. Defaults to empty.

    def initialize(deployment_name, options = {})
      @deployment_name = deployment_name
      options ||= {}
      cleanup = options.dig('cleanup')
      @cleanup = cleanup.nil? ? true : cleanup # we enable cleanup unless specified in deployment
      @no_redact = options.dig('no_redact') || false
      @dry_run = options.dig('dry_run') || false
      @fix = options.dig('fix') || false
      @recreate = options.dig('recreate') || false
      @skip_drain = options.dig('skip_drain') || []
      @max_in_flight = options.dig('max_in_flight') || nil
    end

    def cleanup?
      @cleanup
    end

    def no_redact?
      @no_redact
    end

    def dry_run?
      @dry_run
    end

    def fix?
      @fix
    end

    def recreate?
      @recreate
    end

    def skip_drain?
      !@skip_drain&.empty?
    end

    def max_in_flight?
      !(@max_in_flight.nil? || @max_in_flight.zero?)
    end
  end

  class GitDeploymentDetails
    attr_reader :deployment_name, :submodule_recursive

    DEFAULT_DEPTH_VALUE = 0

    def initialize(deployment_name, options = {})
      @deployment_name = deployment_name
      options ||= {}
      @submodule_recursive = options.dig('submodule_recursive') || false
      @depth = options.dig('depth') || nil
    end

    def depth?
      !@depth.nil?
    end

    def depth
      if @depth.nil? || @depth.negative?
        DEFAULT_DEPTH_VALUE
      else
        @depth
      end
    end
  end
end
