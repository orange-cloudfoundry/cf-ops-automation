#!/usr/bin/env ruby
require 'yaml'
require_relative '../../lib/deployment_deployers_config'
require_relative '../../lib/coa_upgrader'

OPTIONS = {
  dump_output: true,
  config_path: '',
  templates_path: '../paas-templates'
}.freeze

options = CoaUpgrader::CommandLineParser.new(OPTIONS.dup).parse
paas_template_root = options[:templates_path]

raise "invalid paas_template_root: <#{paas_template_root}> does not exist" unless Dir.exist?(paas_template_root)

def delete_stemcells_key(deployment_dependencies)
  migrated = false
  deployment_dependencies['deployment']&.each do |_, details|
    details&.delete('stemcells') && migrated = true
  end
  migrated
end

def remove_stemcell_key_from_deployment_dependencies(deployment_dependencies_files)
  migrated_counter = 0
  deployment_dependencies_files&.each do |deployment_dependencies_filename|
    deployment_dependencies = YAML.load_file(deployment_dependencies_filename)
    unless deployment_dependencies
      puts "*** ignoring file: #{deployment_dependencies_filename} - invalid format"
      next
    end
    puts "original #{deployment_dependencies_filename}: #{deployment_dependencies}"

    if delete_stemcells_key(deployment_dependencies)
      migrated_counter += 1
      puts "migrated #{deployment_dependencies_filename}: #{deployment_dependencies}"
    end
    File.open(deployment_dependencies_filename, 'w') { |file| file.write deployment_dependencies.to_yaml }
    puts '#########'
  end
  migrated_counter
end

puts "scanning for deployment-dependencies in #{paas_template_root}"

deployment_dependencies_files = Dir["#{paas_template_root}/**/deployment-dependencies.yml"]

migrated_deployment_dependencies_counter = remove_stemcell_key_from_deployment_dependencies(deployment_dependencies_files)

puts
puts 'Summary:'
puts "  #{migrated_deployment_dependencies_counter}/#{deployment_dependencies_files.length} deployment-dependencies.yml migrated"
puts

puts
puts 'Thanks, Orange CloudFoundry SKC'
