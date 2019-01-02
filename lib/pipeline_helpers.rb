module PipelineHelpers
  require_relative 'config'
  require_relative './pipeline_helpers/pipeline_configurer'
  require_relative './pipeline_helpers/config_getter'
  require_relative './pipeline_helpers/configured_parallel_execution_limit'
  require_relative './pipeline_helpers/configured_serial_group_naming_strategy'
  require_relative './pipeline_helpers/serial_group_naming_strategy'
  require_relative './pipeline_helpers/serial_group_md5_naming_strategy'
  require_relative './pipeline_helpers/serial_group_round_robin_naming_strategy'

  TERRAFORM_CONFIG_DIRNAME_KEY = 'terraform_config'.freeze
  UNLIMITED_EXECUTION = -1

  class << self
    def bosh_io_hosted?(info)
      info["base_location"]&.include?("bosh.io")
    end

    def generate_vars_files(templates_dir, config_dir, pipeline_name, root_deployment)
      vars_files = Dir[File.join(config_dir, 'credentials-*.yml')].reject { |file_path| filter_credentials_file(file_path) }
      current_pipeline_config_file = generate_pipeline_credentials_filename(config_dir, pipeline_name)
      vars_files.sort!
      puts "INFO - checking existence of #{current_pipeline_config_file}"
      vars_files << current_pipeline_config_file if File.exist?(current_pipeline_config_file)
      versions_file = File.join(templates_dir, root_deployment, "#{root_deployment}-versions.yml")
      raise "Missing version file: #{versions_file}" unless File.exist?(versions_file)
      vars_files << versions_file
      vars_files
    end

    def git_resource_selected_paths(opts = {})
      paths = opts[:defaults] || []
      paths << '.gitmodules' if opts[:git_submodules]&.dig(opts[:depls], opts[:name])
      paths += opts[:config].dig('resources', opts[:config_key], 'extended_scan_path') || []
      joined_paths = paths.flatten.compact.join("', '")
      "'#{joined_paths}'"
    end

    private

    def generate_pipeline_credentials_filename(config_dir, pipeline_name)
      config_file_suffix = pipeline_name.gsub('-generated', '')
      config_file_suffix += '-pipeline' unless config_file_suffix.end_with?('-pipeline')
      File.join(config_dir, "credentials-#{config_file_suffix}.yml")
    end

    def filter_credentials_file(file_path)
      File.basename(file_path).include?('pipeline') || File.basename(file_path).include?('generated')
    end
  end
end
