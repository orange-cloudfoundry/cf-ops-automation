#!/usr/bin/env ruby
require_relative './concourse_pipeline_resource_config_generator'

pipelines_path = ENV.fetch('PIPELINES_PATH')
config_path = ENV.fetch('CONFIG_PATH')
templates_path = ENV.fetch('TEMPLATES_PATH')
output_path = ENV.fetch('OUTPUT_PATH')

puts "Extracted environment variables"
pipeline_generator = ConcoursePipelineResourceConfigGenerator.new(pipelines_path, config_path, templates_path, output_path)

puts "Executing concourse pipeline generator"
success = pipeline_generator.execute
exit 1 unless success
