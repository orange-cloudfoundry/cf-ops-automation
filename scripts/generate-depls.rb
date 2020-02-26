#!/usr/bin/env ruby

require_relative '../lib/pipeline_generator'

options = PipelineGenerator::Parser.parse(ARGV)
puts "Parsed options: #{options}"
pipeline_generator = PipelineGenerator.new(options)
success = pipeline_generator.execute
exit 1 unless success

pipeline_generator.display_warnings
