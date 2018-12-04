#!/usr/bin/env ruby

require 'yaml'
require 'optparse'
require_relative '../lib/../lib/pipeline_helpers'

# Argument parsing
OPTIONS = {
  depls: 'ops-depls',
  no_interactive: false,
  fail_fast: false,
  fail_on_error: true,
  coa_config: true
}

opt_parser = OptionParser.new do |opts|
  opts.banner = 'Usage: ./scripts/concourse-manual-pipelines-update.sh [options]
Customization using ENVIRONMENT_VARIABLE:
    SECRETS: secrets repo to use - Default: ../preprod-secrets
    PAAS_TEMPLATES: paas-templates to use - Default: ../paas-templates
    DEBUG: enable debug message - Default: false
    PIPELINES_DIR: pipelines ready to be uploaded directory- Default: boostrap-generated/pipelines
    TARGET_NAME - Default: fe-int
'

  opts.on("--without=WITHOUT", "-wWITHOUT", "Don't update matched pipelines") do |without_string|
    OPTIONS[:without] = without_string
  end

  opts.on("--match=MATCH", "-mMATCH", "Only update matched pipelines") do |match_string|
    OPTIONS[:match] = match_string
  end

  opts.on("--template=TEMPLATE", "-tTEMPLATE", "Only update pipelines from the specified template") do |template_string|
    OPTIONS[:template] = template_string
  end

  opts.on("--depls=DEPLS", "-dDEPLS", "Only update pipelines from the specified template") do |depls_string|
    OPTIONS[:depls] = depls_string
  end

  opts.on('--no-interactive', 'Do not ask for confirmation on pipeline load') do
    OPTIONS[:no_interactive] = true
  end

  opts.on('--[no-]fail-fast', "Fail on first loading error - Default: #{OPTIONS[:fail_fast]}") do |boolean_option|
    OPTIONS[:fail_fast] = boolean_option
  end

  opts.on('--[no-]fail-on-error', "Fail on loading error - Default: #{OPTIONS[:fail_on_error]}") do |boolean_option|
    OPTIONS[:fail_on_error] = boolean_option
  end
  opts.on('--[no-]use-coa-config', "Use configuration - Default: #{OPTIONS[:coa_config]}") do |boolean_option|
    OPTIONS[:coa_config] = boolean_option
  end
end
opt_parser.parse!

SECRETS = ENV['SECRETS'] || "../int-secrets"
PAAS_TEMPLATES = ENV['PAAS_TEMPLATES'] || '../paas-templates'
DEBUG = ENV['DEBUG'] || false
PIPELINES_DIR = ENV['PIPELINES_DIR'] || 'bootstrap-generated/pipelines'
TARGET_NAME = ENV['TARGET_NAME'] || 'fe-int'
PIPELINE_PREFIX = ENV['PIPELINE_PREFIX'] || ''

def header(msg)
  print '*' * 10
  puts " #{msg}"
end

def get_pipeline_name(name)
  "#{PIPELINE_PREFIX}#{name}"
end

def set_pipeline(target_name:, name:, config:, load: [], options: [])
  return if OPTIONS.key?(:match) && !name.include?(OPTIONS[:match])
  return if OPTIONS.key?(:without) && name.include?(OPTIONS[:without])
  puts "   Setting #{name} pipeline"

  fly_cmd = %{bash -c "fly -t #{target_name} set-pipeline \
    -p #{get_pipeline_name(name)} \
    -c #{config} \
  #{load.collect { |l| "-l #{l}" }.join(' ')} \
  #{options.collect(&:to_s).join(' ')}
  "}

  puts "Executing: #{fly_cmd}"

  pipeline_successfully_loaded = system(fly_cmd)
  puts "Pipeline successfully loaded: #{pipeline_successfully_loaded}"
  if OPTIONS[:fail_fast] && !pipeline_successfully_loaded
    raise "Failed to load pipeline #{get_pipeline_name(name)} from template #{name}"
  end
  pipeline_successfully_loaded
end

def generate_full_path_for_concourse_vars_files(vars_files)
  vars_files_with_path = []
  return vars_files_with_path if vars_files.nil?
  vars_files.each do |var_file|
    vars_files_with_path << if var_file =~ /versions.yml/
                              "#{PAAS_TEMPLATES}/#{var_file}"
                            else
                              "#{SECRETS}/#{var_file}"
                            end
  end
  vars_files_with_path
end

def get_vars_files_with_path(pipeline_options, pipeline_name, root_depls)
  coa_config_dir = File.join(SECRETS, "coa", "config")
  if OPTIONS[:coa_config]
    puts "Use vars_files dynamic detection located in <#{coa_config_dir}>"
    PipelineHelpers.generate_vars_files(PAAS_TEMPLATES, coa_config_dir, pipeline_name, root_depls)
  else
    puts 'Use vars_files listed in ci-deployment-overview.yml files'
    generate_full_path_for_concourse_vars_files(pipeline_options['vars_files'])
  end
end

def concourse_additional_options
  additional_config = []
  additional_config << "--non-interactive" if OPTIONS[:no_interactive]
  additional_config
end

def load_pipeline_into_concourse(pipeline_name, pipeline_vars_files, pipeline_definition_filename, concourse_target_name)
  raise "No vars_files detected. Please ensure coa-config option is #{OPTIONS[:coa_config]}" if pipeline_vars_files&.empty?
  set_pipeline(
    target_name: concourse_target_name,
    name: pipeline_name,
    config: pipeline_definition_filename,
    load: pipeline_vars_files,
    options: concourse_additional_options
  )
end

def load_pipeline_configuration(root_deployment, pipeline_name)
  ci_deployment_overview = YAML.load_file(File.join(SECRETS, root_deployment, 'ci-deployment-overview.yml'))

  pipelines = ci_deployment_overview['ci-deployment'][root_deployment]['pipelines']
  pipelines[pipeline_name]
end

def filter_root_deployment_pipelines(root_deployment)
  header("For pipelines in #{PIPELINES_DIR}")
  Dir["#{PIPELINES_DIR}/*.yml"]
    .reject { |filename| OPTIONS.key?(:depls) && !filename.include?(root_deployment) }
    .reject { |filename| OPTIONS.key?(:template) && !filename.include?(OPTIONS[:template]) }
end

def display_invalid_config_error_message(pipeline_filename, root_deployment)
  pipeline_name = pipeline_name(pipeline_filename)
  puts "invalid config #{SECRETS}/#{root_deployment}/ci-deployment-overview.yml should contains a key ...[pipelines][#{pipeline_name}][vars_files]"
  puts "ignoring pipeline #{pipeline_filename} (invalid config #{SECRETS}/#{root_deployment}/ci-deployment-overview.yml)"
end

def pipeline_name(pipeline_filename)
  File.basename(pipeline_filename, '.yml')
end

def pipeline_config_valid?(current_pipeline)
  !OPTIONS[:coa_config] && current_pipeline.nil?
end

def update_pipelines(target_name)
  loaded_pipelines_status = {}
  root_deployment = OPTIONS[:depls]

  root_deployment_pipelines = filter_root_deployment_pipelines(root_deployment)

  root_deployment_pipelines.each do |pipeline_filename|
    puts "Starting processing of #{pipeline_filename}"
    pipeline_name = pipeline_name(pipeline_filename)
    current_pipeline_options = load_pipeline_configuration(root_deployment, pipeline_name)

    if pipeline_config_valid?(current_pipeline_options)
      display_invalid_config_error_message(pipeline_filename, root_deployment)
      next
    end
    vars_files_with_path = get_vars_files_with_path(current_pipeline_options, pipeline_name, root_deployment)

    pipeline_loading_status = load_pipeline_into_concourse(pipeline_name, vars_files_with_path, pipeline_filename, target_name)
    loaded_pipelines_status[pipeline_name] = pipeline_loading_status
  end

  if OPTIONS[:fail_on_error]
    raise "pipeline loading error. Summary #{loaded_pipelines_status}" unless loaded_pipelines_status.select { |_, status| !status.nil? && !status }.empty?
  end
end

update_pipelines TARGET_NAME
