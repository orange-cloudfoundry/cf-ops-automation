module PipelineHelpers
  require_relative 'config'

  TERRAFORM_CONFIG_DIRNAME_KEY = 'terraform_config'.freeze

  class << self
    def bosh_io_hosted?(info)
      info["base_location"]&.include?("bosh.io")
    end

    def parallel_execution_limit(config)
      unlimited_execution = -1
      result = config.fetch(Config::CONFIG_DEFAULT_KEY, nil)&.fetch(Config::CONFIG_CONCOURSE_KEY, nil)&.fetch(Config::CONFIG_PARALLEL_EXECUTION_LIMIT_KEY, unlimited_execution)
      result = unlimited_execution if result.nil?
      result
    end

    def enabled_parallel_execution_limit?(config)
      parallel_execution_limit(config) != -1
    end
  end
end
