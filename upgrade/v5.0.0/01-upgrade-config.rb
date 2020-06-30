#!/usr/bin/env ruby
require 'yaml'
require_relative '../../lib/deployment_deployers_config'
require_relative '../../lib/coa_upgrader'

def setup_coa_config(base_dir)
  target_dir = File.join(base_dir, COA_CONFIG_DIR)
  puts "> INFO: creating #{target_dir}"
  FileUtils.mkdir_p(target_dir)
  target_dir
end

def cleanup_pipeline_config(ci_deployment_overview)
  migrated = false
  ci_deployment_overview['ci-deployment']&.each do |_, details|
    details['pipelines']&.delete_if { |pipeline_name, _| pipeline_to_delete?(pipeline_name) }
  end
  migrated
end

def pipeline_to_delete?(name)
  name.end_with?('-s3-stemcell-upload-generated') || name.end_with?('-s3-br-upload-generated') || name.end_with?('-sync-helper-generated')
end

def cleanup_old_pipelines(ci_deployment_overview_files)
  migrated_counter = 0
  ci_deployment_overview_files&.each do |ci_deployment_filename|
    ci_deployment = YAML.load_file(ci_deployment_filename)
    unless ci_deployment
      puts "*** ignoring file: #{ci_deployment_filename} - invalid format"
      next
    end

    puts "Analyzing #{ci_deployment_filename}"
    cleanup_pipeline_config(ci_deployment)
    migrated_counter += 1
    puts "\t>> INFO: migrated #{ci_deployment_filename}"
    File.open(ci_deployment_filename, 'w') { |file| file.write ci_deployment.to_yaml }
  end
  migrated_counter
end

def cleanup_generated_pipeline_dir(files_to_delete)
  files_to_delete&.each do |filename|
    File.unlink(filename)
  end
end

config_path = ARGV[0]
templates_path = ARGV[1]
puts "Config path: #{config_path} - Templates path: #{templates_path}"

raise "invalid config_path: <#{config_path}> does not exist" unless Dir.exist?(config_path)
raise "invalid templates_path: <#{templates_path}> does not exist" unless Dir.exist?(templates_path)


puts "Scanning for credentials in #{config_path}"

selected_ci_deployment_overview_files = Dir["#{config_path}/**/ci-deployment-overview.yml"]
migrated_credentials_counter = cleanup_old_pipelines(selected_ci_deployment_overview_files)

selected_pipeline_configs = Dir[File.join(config_path, 'coa', 'pipelines', 'generated', '**', '*.yml')]&.keep_if do |filename|
  pipeline_name = File.basename(filename,'.yml')
  pipeline_to_delete?(pipeline_name)
end
cleanup_generated_pipeline_dir(selected_pipeline_configs)

puts
puts 'Summary:'
puts "  #{migrated_credentials_counter}/#{selected_ci_deployment_overview_files.length} ci-deployment-overview.yml migrated"
puts

puts "please review the changes applied in <#{config_path}> and commit/push"
puts 'Thanks, Orange CloudFoundry SKC'
