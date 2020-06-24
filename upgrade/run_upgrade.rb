#!/usr/bin/env ruby
require 'open3'
require_relative '../lib/coa_upgrader'

def display_available_versions
  base_dir = File.dirname(__FILE__)
  versions_dir = File.join(base_dir, 'v*')
  Dir[versions_dir].map { |path| File.basename(path)[1..-1] }.sort
end

def process_upgrade_files(config_dir, templates_dir, upgrade_scripts)
  config_dir_as_param = File.absolute_path(config_dir)
  templates_dir_as_param = File.absolute_path(templates_dir)
  overall_status_success = true
  error_message = 'Failed to execute: \n'
  puts "Detected upgrade scripts: #{upgrade_scripts}"
  upgrade_scripts&.sort&.each do |upgrade_script|
    puts "Executing #{upgrade_script.green}: "
    cmd_line = "#{upgrade_script} #{config_dir_as_param} #{templates_dir_as_param}"
    Open3.popen2e(cmd_line.to_s) do |_, stdout_stderr, wait_thr|
      while line = stdout_stderr.gets
        puts(line)
      end
      status = wait_thr.value
      error_message += " - #{upgrade_script}\n" unless status.success?
      overall_status_success &= status.success?
    end
    puts '*' * 20
  end
  raise error_message unless overall_status_success
end

options = CoaUpgrader::CommandLineParser.new.parse

version = options[:version]
full_version = 'v' + version

upgrade_dir = File.join(File.dirname(__FILE__), full_version)
raise "invalid version: <#{version}> does not exist - Available versions: #{display_available_versions}" unless Dir.exist?(upgrade_dir)

upgrade_scripts = Dir[File.join(upgrade_dir, '??-*')]
config_dir = options[:config_path]
templates_dir = options[:templates_path]
templates_dir = '../paas-templates' if templates_dir.empty?
process_upgrade_files(config_dir, templates_dir, upgrade_scripts)
