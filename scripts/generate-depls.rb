#!/usr/bin/env ruby
# encoding: utf-8

require 'optparse'
require_relative '../lib/bosh_certificates'
require_relative '../lib/deployment_factory'
require_relative '../lib/template_processor'
require_relative '../lib/git_modules'
require_relative '../lib/ci_deployment_overview'
require_relative '../lib/secrets'
require_relative '../lib/cf_app_overview'
require_relative '../lib/root_deployment'
require_relative '../lib/root_deployment_version'


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

BOSH_CERT = BoshCertificates.new.load_from_location OPTIONS[:secret_path], BOSH_CERT_LOCATIONS

secrets_dirs_overview = Secrets.new("#{OPTIONS[:secret_path]}/*").overview

raise "#{depls}-versions.yml: file not found. #{OPTIONS[:paas_template_root]}/#{depls}/#{depls}-versions.yml does not exist" unless File.exist? "#{OPTIONS[:paas_template_root]}/#{depls}/#{depls}-versions.yml"
# version_reference = YAML.load_file("#{OPTIONS[:paas_template_root]}/#{depls}/#{depls}-versions.yml")
root_deployment_versions = RootDeploymentVersion.load_file("#{OPTIONS[:paas_template_root]}/#{depls}/#{depls}-versions.yml")

deployment_factory = DeploymentFactory.new(depls.to_s, root_deployment_versions.versions)
puts root_deployment_versions.versions
all_dependencies = RootDeployment.new(depls.to_s, OPTIONS[:paas_template_root].to_s, OPTIONS[:secret_path].to_s).overview_from_hash(deployment_factory)

all_ci_deployments = CiDeploymentOverview.new("#{OPTIONS[:secret_path]}/" + depls).overview

all_cf_apps = CfAppOverview.new(File.join(OPTIONS[:secret_path], depls, '/*'), depls).overview

git_submodules = GitModules.list(OPTIONS[:git_submodule_path])

erb_context = {
  depls: depls,
  bosh_cert: BOSH_CERT,
  secrets_dirs_overview: secrets_dirs_overview,
  version_reference: root_deployment_versions.versions,
  all_dependencies: all_dependencies,
  all_ci_deployments: all_ci_deployments,
  all_cf_apps: all_cf_apps,
  git_submodules: git_submodules
}

processor = TemplateProcessor.new depls, OPTIONS, erb_context


processed_template_count = 0
OPTIONS[:input_pipelines].each do |dir|
  processed_template_count += processor.process(dir)
end

if processed_template_count.positive?
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
