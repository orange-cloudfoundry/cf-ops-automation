#!/usr/bin/env ruby

require 'yaml'
require 'optparse'

# Argument parsing
OPTIONS = {
  depls: 'ops-depls',
  no_interactive: false,
  fail_fast: false,
  fail_on_error: false
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

  opts.on('--no-interactive', 'Do not ask for confirmation on pipeline load') do |_|
    OPTIONS[:no_interactive] = true
  end

  opts.on('--fail-fast', 'Fail on first loading error') do |_|
    OPTIONS[:fail_fast] = true
  end

  opts.on('--fail-on-error', 'Fail on loading error') do |_|
    OPTIONS[:fail_on_error] = true
  end
end
opt_parser.parse!

SECRETS = ENV['SECRETS'] || "../preprod-secrets"
PAAS_TEMPLATES = ENV['PAAS_TEMPLATES'] || '../paas-templates'
DEBUG = ENV['DEBUG'] || false
PIPELINES_DIR = ENV['PIPELINES_DIR'] || 'bootstrap-generated/pipelines'

target_name = ENV['TARGET_NAME'] || 'fe-int'

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
  vars_files.each do |var_file|
    vars_files_with_path << if var_file =~ /versions.yml/
                              "#{PAAS_TEMPLATES}/#{var_file}"
                            else
                              "#{SECRETS}/#{var_file}"
                            end
  end
  vars_files_with_path
end

def update_pipelines(target_name)
  header("For pipelines in #{PIPELINES_DIR}")
  loaded_pipelines_status = {}
  depls = OPTIONS[:depls]
  Dir["#{PIPELINES_DIR}/*.yml"].each do |filename|
    # puts "Found #{filename}"
    next if OPTIONS.key?(:depls) && !filename.include?(OPTIONS[:depls])
    next if OPTIONS.key?(:template) && !filename.include?(OPTIONS[:template])
    puts "Starting processing of #{filename}"
    deployment_name = File.basename(filename, '.yml')
    ci_deployment_overview = YAML.load_file("#{SECRETS}/#{depls}/ci-deployment-overview.yml")

    pipelines = ci_deployment_overview['ci-deployment'][depls]['pipelines']
    current_pipeline = pipelines[deployment_name]
    if current_pipeline.nil?
      puts "invalid config #{SECRETS}/#{depls}/ci-deployment-overview.yml should contains a key ...[pipelines][#{deployment_name}][vars_files]"
      puts "ignoring pipeline #{filename} (invalid config #{SECRETS}/#{depls}/ci-deployment-overview.yml)"
      next
    end

    additional_config = []
    additional_config << "--non-interactive" if OPTIONS[:no_interactive]

    vars_files_with_path = generate_full_path_for_concourse_vars_files(current_pipeline['vars_files'])
    result = set_pipeline(
      target_name: target_name,
      name: deployment_name,
      config: filename,
      load: vars_files_with_path,
      options: additional_config
    )
    loaded_pipelines_status[deployment_name] = result
  end

  if OPTIONS[:fail_on_error]
    raise "pipeline loading error. Summary #{loaded_pipelines_status}" unless loaded_pipelines_status.select { |_, status| !status.nil? && !status }.empty?
  end
end

update_pipelines target_name
