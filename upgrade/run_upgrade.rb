#!/usr/bin/env ruby
require 'open3'
require_relative '../lib/coa_upgrader'

def display_available_versions
  base_dir = File.dirname(__FILE__)
  versions_dir = File.join(base_dir, 'v*')
  Dir[versions_dir].map { |path| File.basename(path)[1..-1] }.sort
end


params = ARGV.dup.join(' ')
options = CoaUpgrader::CommandLineParser.new.parse

version = options[:version]
full_version = 'v' + version

upgrade_dir = File.join(File.dirname(__FILE__), full_version)
raise "invalid version: <#{version}> does not exist - Available versions: #{display_available_versions}" unless Dir.exist?(upgrade_dir)



Dir[File.join(upgrade_dir, '??-*')].sort.each do |upgrade_script|
  puts "Executing #{upgrade_dir}: "
  cmd_line = "#{upgrade_script} #{params}"
  out, err, = Open3.capture3(cmd_line.to_s)
  puts out unless out.empty?
  raise err unless err.empty?
end