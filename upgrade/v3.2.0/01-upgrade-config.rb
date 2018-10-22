#!/usr/bin/env ruby
require 'yaml'
require_relative '../../lib/deployment_deployers_config'
require_relative '../../lib/coa_upgrader'

options = CoaUpgrader::CommandLineParser.new.parse

config_path = options[:config_path]

COA_CONFIG_DIR = File.join("coa", "config")

raise "invalid config_path: <#{config_path}> does not exist" unless Dir.exist?(config_path)

def select_credentials_files(credentials_files)
  credentials_files.reject { |path| path.include?(COA_CONFIG_DIR) }
end

def setup_coa_config(base_dir)
  target_dir = File.join(base_dir, COA_CONFIG_DIR)
  puts "\t>> INFO: creating #{target_dir}"
  FileUtils.mkdir_p(target_dir)
  target_dir
end

def process_credentials_files(target_dir, credentials_files)
  migrated_counter = 0
  credentials_files.each do |file|
    puts "\t>> INFO: copying #{file} to #{target_dir}"
    FileUtils.cp(file, target_dir)
    migrated_counter += 1
  end
  migrated_counter
end

def create_bosh_pipeline_links(coa_credentials_files)
  coa_credentials_files.dup.keep_if {|filepath| File.basename(filepath, ".yml") =~ /credentials-([a-z]|[A-Z]|[0-9])+-depls-pipeline/}
    .flat_map do |filepath|
    source = File.basename(filepath)
    new_filename = filepath.gsub(/credentials-(([a-z]|[A-Z]|[0-9])+)-depls-pipeline.yml/, 'credentials-\1-depls-bosh-pipeline.yml')
    puts "\t>> INFO: creating link #{File.basename(new_filename)} on #{source}"
    FileUtils.ln_s(source, new_filename, force: true)
  end
end

def delete_useless_credentials(coa_credentials_files)
  to_be_deleted = %w[credentials-mattermost-certs.yml credentials-cloudflare-depls-bosh-pipeline.yml]
  coa_credentials_files.dup.select! { |filepath| to_be_deleted.include?(File.basename(filepath)) }
    .map { |filepath| puts "\t>> DEBUG: deleting #{filepath}"; FileUtils.rm(filepath) }
end

def update_for_sync_feature_branches(coa_config, coa_credentials_files)
  coa_credentials_files.dup.select! { |filepath| filepath.include?("credentials-sync-feature-branches.yml") }
    .flat_map do |filepath|
    puts "\t>> INFO: renaming #{filepath}"
    FileUtils.mv(filepath, File.join(coa_config, "credentials-sync-feature-branches-pipeline.yml"))
  end
end

def post_process_coa_config(coa_config)
  coa_credentials_files = Dir["#{coa_config}/credentials-*.yml"]

  create_bosh_pipeline_links(coa_credentials_files)
  update_for_sync_feature_branches(coa_config, coa_credentials_files)
  delete_useless_credentials(coa_credentials_files)
end

def insert_pipeline_config(ci_deployment_overview)
  migrated = false
  ci_deployment_overview['ci-deployment']&.each do |_, details|
    additional_pipelines = {}
    details['pipelines']&.each do |name, pipeline_config|
      if name.end_with?('-init-generated')
        puts "\t>> INFO: checking #{name} configuration"
        update_pipeline_name = name.gsub(%r{(([a-z]|[A-Z]|[0-9])+)-depls-init-generated}, '\1-depls-update-generated')
        vars_files = pipeline_config['vars_files'].map { |path| File.join(COA_CONFIG_DIR, File.basename(path)) }
        additional_pipelines[update_pipeline_name] = vars_files
        migrated = true
      elsif name =~ /(([a-z]|[A-Z]|[0-9])+)-depls-generated/
        puts "\t>> INFO: checking #{name} configuration"
        update_pipeline_name = name.gsub(%r{(([a-z]|[A-Z]|[0-9])+)-depls-generated}, '\1-depls-bosh-generated')
        vars_files = pipeline_config['vars_files'].map { |path| if path.end_with?('-versions.yml'); path; else File.join(COA_CONFIG_DIR, File.basename(path)); end}
        additional_pipelines[update_pipeline_name] = vars_files
        migrated = true
      end
    end
    details['pipelines']&.merge(additional_pipelines)
  end
  migrated
end


def insert_new_pipeline_configuration(ci_deployment_overview_files)
  migrated_counter = 0
  ci_deployment_overview_files&.each do |ci_deployment_filename|
    ci_deployment = YAML.load_file(ci_deployment_filename)
    unless ci_deployment
      puts "*** ignoring file: #{ci_deployment_filename} - invalid format"
      next
    end
    # puts "original #{ci_deployment_filename}: #{deployment_dependencies}"

    puts "Analyzing #{ci_deployment_filename}"
    if insert_pipeline_config(ci_deployment)
      migrated_counter += 1
      puts "\t>> INFO: migrated #{ci_deployment_filename}"
      File.open(ci_deployment_filename, 'w') { |file| file.write ci_deployment.to_yaml }
    else
      puts "\t>> INFO: ignored #{ci_deployment_filename}"
    end
  end
  migrated_counter
end


coa_config = setup_coa_config(config_path)

puts "Scanning for credentials in #{config_path}"
credentials_files = Dir["#{config_path}/**/credentials-*.yml"]
selected_credentials_files = select_credentials_files(credentials_files)
migrated_coa_credentials_counter = process_credentials_files(coa_config, selected_credentials_files)
post_process_coa_config(coa_config)

selected_ci_deployment_overview_files = Dir["#{config_path}/**/ci-deployment-overview.yml"]
migrated_credentials_counter = insert_new_pipeline_configuration(selected_ci_deployment_overview_files)

puts
puts 'Summary:'
puts "  #{migrated_coa_credentials_counter}/#{selected_credentials_files.length} credentials files migrated"
puts "  #{migrated_credentials_counter}/#{selected_ci_deployment_overview_files.length} ci-deployment-overview.yml migrated"
puts

puts "please review the changes applied in <#{config_path}> and commit/push"
puts 'Thanks, Orange CloudFoundry SKC'
