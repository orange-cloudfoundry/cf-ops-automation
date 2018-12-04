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

    def generate_vars_files(templates_dir, config_dir, pipeline_name, root_deployment)
      vars_files = Dir[File.join(config_dir, 'credentials-*.yml')].reject { |file_path| filter_credentials_file(file_path) }
      current_pipeline_config_file = generate_pipeline_credentials_filename(config_dir, pipeline_name)
      puts "INFO - checking existence of #{current_pipeline_config_file}"
      vars_files << current_pipeline_config_file if File.exist?(current_pipeline_config_file)
      versions_file = File.join(templates_dir, root_deployment, "#{root_deployment}-versions.yml")
      raise "Missing version file: #{versions_file}" unless File.exist?(versions_file)
      vars_files << versions_file
      vars_files
    end

    private

    def generate_pipeline_credentials_filename(config_dir, pipeline_name)
      config_file_suffix = pipeline_name.gsub('-generated', '')
      config_file_suffix += '-pipeline' unless config_file_suffix.end_with?('-pipeline')
      File.join(config_dir, "credentials-#{config_file_suffix}.yml")
    end

    def extract_parallel_execution_limit(config, root_deployment_name)
      config.fetch(root_deployment_name, nil)&.fetch(Config::CONFIG_CONCOURSE_KEY, nil)&.fetch(Config::CONFIG_PARALLEL_EXECUTION_LIMIT_KEY, UNLIMITED_EXECUTION)
    end

    def filter_credentials_file(file_path)
      File.basename(file_path).include?('pipeline') || File.basename(file_path).include?('generated')
    end
  end
end
