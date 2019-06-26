#!/usr/bin/env ruby
require_relative './concourse_pipeline_resource_config_generator'

pipelines_path = ENV.fetch('PIPELINE_PATH')
config_path = ENV.fetch('CONFIG_PATH')
output_path = ENV.fetch('OUTPUT_PATH')

pipeline_generator = ConcoursePipelineResourceConfigGenerator.new(pipelines_path, config_path, output_path)

success = pipeline_generator.execute
exit 1 unless success
