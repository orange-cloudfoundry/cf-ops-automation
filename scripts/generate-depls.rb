#!/usr/bin/env ruby

require_relative '../lib/pipeline_generator.rb'

options = PipelineGenerator::Parser.parse(ARGV)
puts "Parsed options: #{options}"
pipeline_generator = PipelineGenerator.new(options)

success = pipeline_generator.execute
exit 1 if !success

pipeline_generator.display_warnings
