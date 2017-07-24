#!/usr/bin/env ruby
# encoding: utf-8

require 'optparse'
require 'erb'
require_relative '../lib/deployments_generator'


def header(msg)
  print '*' * 10
  puts " #{msg}"
end


# TODO add rspec file to avoid regression
BOSH_CERT_LOCATIONS={
'on-demand-depls' => 'shared/certs/internal_paas-ca/server-ca.crt',
'micro-depls' => 'shared/certs/internal_paas-ca/server-ca.crt',
'master-depls' => 'shared/certs/internal_paas-ca/server-ca.crt',
'expe-depls' => 'shared/certs/internal_paas-ca/server-ca.crt',
'ops-depls' => 'shared/certs/internal_paas-ca/server-ca.crt'
}
BOSH_CERT_LOCATIONS.default = 'shared/certs/internal_paas-ca/server-ca.crt'

# Argument parsing
OPTIONS = {
  :git_submodule_path => '../paas-templates',
  :secret_path => '..',
  :output_path => 'bootstrap-generated',
  :ops_automation => '.',
  :dump_output => true,
  :paas_template_root => '../paas-templates'
}
opt_parser = OptionParser.new do |opts|
  opts.banner = "Incomplete/wrong parameter(s): #{opts.default_argv}.\n Usage: ./#{opts.program_name} <options>"

  opts.on('-d', "--depls DEPLOYMENT", "Specify a deployment name to generate template for. MANDATORY") do |deployment_string|
    OPTIONS[:depls]= deployment_string
  end

  opts.on('-t', "--templates-path PATH", "Base location for paas-templates (implies -s)") do |tp_string|
    OPTIONS[:paas_template_root] = tp_string
    OPTIONS[:git_submodule_path] = tp_string
  end

  opts.on('-s', "--git-submodule-path PATH", ".gitsubmodule path") do |gsp_string|
    OPTIONS[:git_submodule_path] = gsp_string
  end

  opts.on('-p', "--secrets-path PATH", "Base secrets dir (ie: enable-deployment.yml,enable-cf-app.yml, etc...).") do |sp_string|
    OPTIONS[:secret_path] = sp_string
  end

  opts.on('-o', "--output-path PATH", 'Output dir for generated pipelines.') do |op_string|
    OPTIONS[:output_path] = op_string
  end

  opts.on('-a', '--automation-path PATH', "Base location for cf-ops-automation") do |ap_string|
    OPTIONS[:ops_automation] = ap_string
  end

  opts.on('-i', '--input PIPELINE1,PIPELINE2,', Array, 'List of pipelines to process') do |ip_array|
    OPTIONS[:input_pipelines] = ip_array
  end

  opts.on('--[no-]dump', 'Dump genereted file on standart output') do |dump|
    OPTIONS[:dump_output] = dump
  end

end
opt_parser.parse!

depls = OPTIONS[:depls]
opt_parser.abort("#{opt_parser}") if depls.nil?

if OPTIONS[:input_pipelines].nil?
  OPTIONS[:input_pipelines] =
  [
    "#{OPTIONS[:ops_automation]}/concourse/pipelines/template/depls-pipeline.yml.erb",
    "#{OPTIONS[:ops_automation]}/concourse/pipelines/template/cf-apps-pipeline.yml.erb",
    "#{OPTIONS[:ops_automation]}/concourse/pipelines/template/news-pipeline.yml.erb",
    "#{OPTIONS[:ops_automation]}/concourse/pipelines/template/sync-helper-pipeline.yml.erb",
    "#{OPTIONS[:ops_automation]}/concourse/pipelines/template/init-pipeline.yml.erb"
  ]
end

generator = DeploymentsGenerator.new
BOSH_CERT = generator.load_cert_from_location OPTIONS[:secret_path], BOSH_CERT_LOCATIONS

secrets_dirs_overview = generator.generate_secrets_dir_overview("#{OPTIONS[:secret_path]}/*")

raise "#{depls}-versions.yml: file not found. #{OPTIONS[:paas_template_root]}/#{depls}/#{depls}-versions.yml does not exist" unless File.exist? "#{OPTIONS[:paas_template_root]}/#{depls}/#{depls}-versions.yml"
version_reference = YAML.load_file("#{OPTIONS[:paas_template_root]}/#{depls}/#{depls}-versions.yml")
all_dependencies = generator.generate_deployment_overview_from_hash("#{depls}","#{OPTIONS[:paas_template_root]}/", "#{OPTIONS[:secret_path]}/" + depls + '/*', version_reference)

all_ci_deployments = generator.generate_ci_deployment_overview("#{OPTIONS[:secret_path]}/" + depls)

all_cf_apps = generator.generate_cf_app_overview("#{OPTIONS[:secret_path]}/#{depls}/*",depls)

git_submodules = generator.list_git_submodules(OPTIONS[:git_submodule_path])
processed_template_count = 0

puts OPTIONS[:input_pipelines]

OPTIONS[:input_pipelines].each do |dir|
  Dir[dir].each do |filename|
    processed_template_count += 1

    puts "processing #{filename}"
    output = ERB.new(File.read(filename), 0, '<>').result
    puts output if OPTIONS[:dump_output]

    # trick to avoid pipeline name like ops-depls-depls-generated or ops-depls--generated
    tmp_pipeline_name = filename.split('/').last.chomp('-pipeline.yml.erb').chomp('depls')
    pipeline_name = "#{depls}-"
    pipeline_name << "#{tmp_pipeline_name}-" if ! tmp_pipeline_name.nil? && ! tmp_pipeline_name.empty?
    pipeline_name << 'generated.yml'

    puts "Pipeline name #{pipeline_name}"
    Dir.mkdir(OPTIONS[:output_path]) unless Dir.exist?(OPTIONS[:output_path])
    target_dir = "#{OPTIONS[:output_path]}/pipelines"
    Dir.mkdir(target_dir) unless Dir.exist?(target_dir)
    aPipeline = File.new("#{OPTIONS[:output_path]}/pipelines/#{pipeline_name}", 'w')
    aPipeline << output
    puts "Trying to parse generated Yaml: #{pipeline_name} (#{aPipeline&.path})"
    YAML.load_file(aPipeline)
    puts "> #{pipeline_name} seems a valid Yaml file"
    puts '####################################################################################'
    puts '####################################################################################'
  end
end

if processed_template_count > 0
  puts "#{processed_template_count} concourse pipeline templates were processed"
else
  puts "ERROR: no concourse pipeline templates found in #{OPTIONS[:ops_automation]}/concourse/pipelines/template/"
  puts 'ERROR: use -a option to set cf-ops-automation root dir <AUTOMATION_ROOT_DIR>/concourse/pipelines/template/'
  exit 1
end

puts
puts
puts "### WARNING ### no deployment detected. Please check
 template_dir: #{OPTIONS[:paas_template_root]}
 secrets_dir: #{OPTIONS[:secret_path]}" if  all_dependencies.empty?
puts '### WARNING ### no ci deployment detected. Please check a valid ci-deployment-overview.yml exists' if all_ci_deployments.empty?
puts '### WARNING ### no cf app deployment detected. Please check a valid enable-cf-app.yml exists' if all_cf_apps.empty?
puts '### WARNING ### no gitsubmodule detected' if git_submodules.empty?
puts
puts 'Thanks, Orange CloudFoundry SKC'
