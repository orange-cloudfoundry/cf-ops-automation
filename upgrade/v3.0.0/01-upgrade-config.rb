#!/usr/bin/env ruby
require 'yaml'
require_relative '../../lib/deployment_deployers_config'
require_relative '../../lib/coa_upgrader'

options = CoaUpgrader::CommandLineParser.new.parse

config_path = options[:config_path]

raise "invalid config_path: <#{config_path}> does not exist" unless Dir.exist?(config_path)

def insert_iaas_specific_pipeline(ci_deployment_overview)
  migrated = false
  ci_deployment_overview['ci-deployment']&.each do |_, details|
    details['pipelines']&.each do |name, pipeline_config|
      if name.end_with?('-init-generated') || name == 'bootstrap-all-init-pipelines'
        puts "\t>> INFO: checking #{name} configuration"
        if pipeline_config['vars_files'].include?('micro-depls/concourse-micro/pipelines/credentials-iaas-specific.yml')
          puts "\t>> INFO: required credentials already part of #{name} configuration"
        else
          pipeline_config['vars_files'] << 'micro-depls/concourse-micro/pipelines/credentials-iaas-specific.yml'
          migrated = true
        end
      end
    end
  end
  migrated
end

def insert_iaas_specific_into_init_pipeline_config(ci_deployment_overview_files)
  migrated_counter = 0
  ci_deployment_overview_files&.each do |ci_deployment_filename|
    ci_deployment = YAML.load_file(ci_deployment_filename)
    unless ci_deployment
      puts "*** ignoring file: #{ci_deployment_filename} - invalid format"
      next
    end
    # puts "original #{ci_deployment_filename}: #{deployment_dependencies}"

    puts "Analyzing #{ci_deployment_filename}"
    if insert_iaas_specific_pipeline(ci_deployment)
      migrated_counter += 1
      puts "\t>> INFO: migrated #{ci_deployment_filename}"
    else
      puts "\t>> INFO: ignored #{ci_deployment_filename}"
    end
    File.open(ci_deployment_filename, 'w') { |file| file.write ci_deployment.to_yaml }
  end
  migrated_counter
end

puts "scanning for ci-deployment-overview in #{config_path}"

selected_ci_deployment_overview_files = Dir["#{config_path}/**/ci-deployment-overview.yml"]

migrated_ci_deployment_overview_counter = insert_iaas_specific_into_init_pipeline_config(selected_ci_deployment_overview_files)

puts
puts 'Summary:'
puts "  #{migrated_ci_deployment_overview_counter}/#{selected_ci_deployment_overview_files.length} ci-deployment-overview.yml migrated"
puts

puts 'please review the changes applied and commit/push'
puts 'Thanks, Orange CloudFoundry SKC'
