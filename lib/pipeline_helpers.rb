module PipelineHelpers
  require_relative 'config'

  TERRAFORM_CONFIG_DIRNAME_KEY = 'terraform_config'.freeze
  UNLIMITED_EXECUTION = -1

  class << self
    def bosh_io_hosted?(info)
      info["base_location"]&.include?("bosh.io")
    end

    def parallel_execution_limit(config, root_deployment_name = '')
      extracted_parallel_execution_limit = extract_parallel_execution_limit(config, root_deployment_name) unless root_deployment_name.to_s.empty?
      extracted_parallel_execution_limit = extract_parallel_execution_limit(config, Config::CONFIG_DEFAULT_KEY) if extracted_parallel_execution_limit.to_s.empty? || extracted_parallel_execution_limit == UNLIMITED_EXECUTION
      extracted_parallel_execution_limit = UNLIMITED_EXECUTION if extracted_parallel_execution_limit.nil?
      extracted_parallel_execution_limit
    end

    def enabled_parallel_execution_limit?(config, root_deployment_name = '')
      parallel_execution_limit(config, root_deployment_name) != UNLIMITED_EXECUTION
    end

    private

    def extract_parallel_execution_limit(config, root_deployment_name)
      config.fetch(root_deployment_name, nil)&.fetch(Config::CONFIG_CONCOURSE_KEY, nil)&.fetch(Config::CONFIG_PARALLEL_EXECUTION_LIMIT_KEY, UNLIMITED_EXECUTION)
    end
  end
end
