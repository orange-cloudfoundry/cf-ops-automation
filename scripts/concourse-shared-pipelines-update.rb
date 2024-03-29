#!/usr/bin/env ruby

require 'yaml'
require 'optparse'
require_relative '../lib/../lib/pipeline_helpers'

# Argument parsing
OPTIONS = {
  depls: 'shared',
  team: 'main',
  no_interactive: false,
  fail_fast: false,
  fail_on_error: true,
  coa_config: true,
  fly_bin: 'fly'
}

opt_parser = OptionParser.new do |opts|
  opts.banner = 'Usage: ./scripts/concourse-manual-pipelines-update.sh [options]
Customization using ENVIRONMENT_VARIABLE:
    SECRETS: secrets repo to use - Default: ../preprod-secrets
    PAAS_TEMPLATES: paas-templates to use - Default: ../paas-templates
    DEBUG: enable debug message - Default: false
    PIPELINES_DIR: pipelines ready to be uploaded directory- Default: boostrap-generated/pipelines
    TARGET_NAME - Default: fe-int
    PIPELINE_PREFIX - Add prefix to pipeline name -Default: ""
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
  opts.on('--team=TEAM', "Concourse team to use to deploy pipelines - Default: #{OPTIONS[:team]}") do |team_string|
    OPTIONS[:team] = team_string
  end
  opts.on('--fly-bin=BINARY', "Fly binary name - Default: #{OPTIONS[:fly_bin]}") do |bin_string|
    OPTIONS[:fly_bin] = bin_string
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

def set_pipeline(target_name:, fly_bin: 'fly', team_name: 'main', name:, config:, load: [], options: [])
  if OPTIONS.key?(:match) && !name.include?(OPTIONS[:match])
    puts "Skipping pipeline loading, '--match' #{OPTIONS[:match]} exclude pipeline #{name}"
    return
  end

  if OPTIONS.key?(:without) && name.include?(OPTIONS[:without])
    puts "Skipping pipeline loading, '--without' #{OPTIONS[:match]} exclude pipeline #{name}"
    return
  end

  puts "   Setting #{name} pipeline"

  switch_team_cmd = %{bash -c "#{fly_bin} -t #{target_name} edit-target -n #{team_name}"}
  switch_concourse_team = system(switch_team_cmd)
  puts "Switched to team: #{team_name}"
  ensure_team_exists_cmd = %{bash -c "#{fly_bin} -t #{target_name} teams|grep #{team_name}"}
  ensure_team_exists = system(ensure_team_exists_cmd)
  raise "Failed to switch team to #{team_name}, required to load pipeline #{get_pipeline_name(name)}" unless ensure_team_exists

  fly_cmd = %{bash -c "#{fly_bin} -t #{target_name} set-pipeline \
    -p #{get_pipeline_name(name)} \
    -c #{config} \
  #{load.collect { |l| "-l #{l}" }.join(' ')} \
  #{options.collect(&:to_s).join(' ')}
  "}

  puts "Executing: #{fly_cmd}"

  pipeline_successfully_loaded = system(fly_cmd)
  puts "Pipeline successfully loaded: #{pipeline_successfully_loaded}"
  raise "Failed to load pipeline #{get_pipeline_name(name)} from template #{name}" if OPTIONS[:fail_fast] && !pipeline_successfully_loaded

  pipeline_successfully_loaded
end

def generate_full_path_for_concourse_vars_files(vars_files)
  vars_files_with_path = []
  return vars_files_with_path if vars_files.nil?

  vars_files.each do |var_file|
    vars_files_with_path << if var_file.match?(/root-deployment.yml/)
                              "#{PAAS_TEMPLATES}/#{var_file}"
                            else
                              "#{SECRETS}/#{var_file}"
                            end
  end
  vars_files_with_path
end

def get_vars_files_with_path(pipeline_name)
  coa_config_dir = File.join(SECRETS, "coa", "config")
  puts "Use vars_files dynamic detection located in <#{coa_config_dir}>"
  PipelineHelpers.generate_vars_files_without_versions(coa_config_dir, pipeline_name)
end

def concourse_additional_options
  additional_config = []
  additional_config << "--non-interactive" if OPTIONS[:no_interactive]
  additional_config
end

def load_pipeline_into_concourse(pipeline_name, pipeline_vars_files, pipeline_definition_filename, concourse_target_name)
  raise "No vars_files detected. Please ensure coa-config option is #{OPTIONS[:coa_config]}" if pipeline_vars_files&.empty?

  pipeline_team_name = OPTIONS[:team]
  fly_bin = OPTIONS[:fly_bin]
  set_pipeline(
    target_name: concourse_target_name,
    fly_bin: fly_bin,
    name: pipeline_name,
    team_name: pipeline_team_name,
    config: pipeline_definition_filename,
    load: pipeline_vars_files,
    options: concourse_additional_options
  )
end

def load_pipeline_configuration(root_deployment, pipeline_name)
  ci_deployment_overview = YAML.load_file(File.join(SECRETS, root_deployment, 'ci-deployment-overview.yml'), aliases: true)

  pipelines = ci_deployment_overview['ci-deployment'][root_deployment]['pipelines']
  pipelines[pipeline_name]
end

def filter_root_deployment_pipelines(root_deployment)
  header("For pipelines in #{PIPELINES_DIR} - #{root_deployment}")
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

    vars_files_with_path = get_vars_files_with_path(pipeline_name)

    pipeline_loading_status = load_pipeline_into_concourse(pipeline_name, vars_files_with_path, pipeline_filename, target_name)
    loaded_pipelines_status[pipeline_name] = pipeline_loading_status
  end

  raise "pipeline loading error. Summary #{loaded_pipelines_status}" if OPTIONS[:fail_on_error] && !loaded_pipelines_status.select { |_, status| !status.nil? && !status }.empty?
end

update_pipelines TARGET_NAME
