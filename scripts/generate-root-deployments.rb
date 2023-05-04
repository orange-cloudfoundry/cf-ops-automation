#!/usr/bin/env ruby

require_relative '../lib/shared_pipeline_generator'
require 'yaml'

def configure_logging(options)
  secrets_path = options[:secrets_path]
  private_config_file = File.join(secrets_path, 'private-config.yml')
  private_config = {}
  YAML.load_file(private_config_file) || {} if File.exist? private_config_file
  log_level = private_config.dig('log', 'level')
  ENV["COA_LOG_LEVEL"] = log_level unless log_level.to_s.empty?
  log_output = private_config.dig('log', 'output')
  ENV["COA_LOG_OUTPUT"] = log_output unless log_output.to_s.empty?
  log_date_format = private_config.dig('log', 'date-format')
  ENV["COA_LOG_DATEFORMAT"] = log_date_format unless log_date_format.to_s.empty?
end

options = SharedPipelineGenerator::Parser.parse(ARGV)
puts "Parsed options: #{options}"
configure_logging(options)
pipeline_generator = SharedPipelineGenerator.new(options)
success = pipeline_generator.execute
exit 1 unless success

pipeline_generator.display_warnings
