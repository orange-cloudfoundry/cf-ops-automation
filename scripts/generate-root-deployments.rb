#!/usr/bin/env ruby

require_relative '../lib/shared_pipeline_generator'

options = SharedPipelineGenerator::Parser.parse(ARGV)
puts "Parsed options: #{options}"
pipeline_generator = SharedPipelineGenerator.new(options)
success = pipeline_generator.execute
exit 1 unless success

pipeline_generator.display_warnings
