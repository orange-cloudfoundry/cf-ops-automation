#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'
require 'optparse'
require 'tempfile'
require_relative '../lib/directory_initializer'

# Argument parsing
OPTIONS = {
  :ops_automation => '.',
  :dump_output => true,
  :paas_template_root=> '../paas-templates'
}
opt_parser = OptionParser.new do |opts|
  opts.banner = "Incomplete/wrong parameter(s): #{opts.default_argv}.\n Usage: ./#{opts.program_name} <options>"

  opts.on('-d', "--depls DEPLOYMENT", "Specify a new root deployment name. MANDATORY.") do |deployment_string|
    OPTIONS[:depls]= deployment_string
  end

  opts.on('-t', "--templates-path PATH", "paas-templates location (main git directory). Default: #{OPTIONS[:paas_template_root]}") do |tp_string|
    OPTIONS[:paas_template_root]= tp_string
  end

  opts.on('-p', "--secrets-path PATH", "secrets locations (main git directory).MANDATORY.") do |sp_string|
    OPTIONS[:secret_path]= sp_string
  end

  opts.on('-a', "--automation-path PATH", "Base location for cf-ops-automation") do |ap_string|
    OPTIONS[:ops_automation]= ap_string
  end

  opts.on("--[no-]dump", 'Dump genereted file on standart output') do |dump|
    OPTIONS[:dump_output]= dump
  end

end
opt_parser.parse!

depls = OPTIONS[:depls]
opt_parser.abort("#{opt_parser}") unless depls && OPTIONS[:secret_path]

dir_initializer = DirectoryInitializer.new depls, OPTIONS[:secret_path], OPTIONS[:paas_template_root]

dir_initializer.setup_secrets!

dir_initializer.setup_templates!

puts
puts 'Thanks, Orange CloudFoundry SKC'
