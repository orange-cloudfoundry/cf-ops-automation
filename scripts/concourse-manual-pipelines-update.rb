#!/usr/bin/env ruby
# encoding: utf-8
# set -e

#echo "Deploy on ${FLY_TARGET} using secrets in $SECRET_DIR"
#for depls in ${DEPLS_LIST};do
#    cd ${SCRIPT_DIR}/concourse
#    ./generate-depls.rb -d ${depls} -p ${SECRET_DIR} -o ${OUTPUT_DIR} --no-dump
#    PIPELINE="${depls}-init-generated"
#    cd ${SCRIPT_DIR}
#    echo "Load ${PIPELINE} on ${FLY_TARGET}"
#    set +e
#    fly -t ${FLY_TARGET} set-pipeline -p ${PIPELINE} -c ${OUTPUT_DIR}/pipelines/${PIPELINE}.yml  \
#                -l ${SECRET_DIR}/micro-depls/concourse-micro/pipelines/credentials-auto-init.yml \
#                -l ${SECRET_DIR}/micro-depls/concourse-micro/pipelines/credentials-mattermost-certs.yml \
#                -l ${SECRET_DIR}/micro-depls/concourse-micro/pipelines/credentials-git-config.yml
#    set -e
#    fly -t ${FLY_TARGET} unpause-pipeline -p ${PIPELINE}
#    if [ "$SKIP_TRIGGER" != "true" ]
#    then
#        fly -t ${FLY_TARGET} trigger-job -j "${PIPELINE}/update-pipeline-${depls}"
#    fi
#done


require 'yaml'
require 'optparse'

# Argument parsing
OPTIONS = {
  :depls => 'ops-depls'
}
opt_parser = OptionParser.new do |opts|
  opts.banner = 'Usage: ./scripts/concourse-manual-pipelines-update.sh [options]
Customization using ENVIRONMENT_VARIABLE:
    SECRETS: secrets repo to use - Default: ../preprod-secrets
    PAAS_TEMPLATES: paas-templates to use - Default: ../paas-templates
    DEBUG: enable debug message - Default: false
    PIPELINES_DIR: pipelines ready to be uploaded directory- Default: boostrap-generated/pipelines
    TARGET_NAME - Default: cw-pp-micro

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
end
opt_parser.parse!

SECRETS = ENV['SECRETS'] ||"../preprod-secrets"
PAAS_TEMPLATES = ENV['PAAS_TEMPLATES'] ||'../paas-templates'
DEBUG = ENV['DEBUG'] || false
PIPELINES_DIR = ENV['PIPELINES_DIR'] || 'bootstrap-generated/pipelines'


flyrc = YAML.load_file(File.expand_path('~/.flyrc'))
target_name = ENV['TARGET_NAME'] || 'cw-pp-micro'
target = flyrc['targets'][target_name]
concourse_url= target['api']

PIPELINE_PREFIX = ENV['PIPELINE_PREFIX'] || ''

def header(msg)
  print '*' * 10
  puts " #{msg}"
end

def set_pipeline(target_name:,name:, config:, load: [])
  return if OPTIONS.has_key?(:match) && !name.include?(OPTIONS[:match])
  return if OPTIONS.has_key?(:without) && name.include?(OPTIONS[:without])
  puts "   #{name} pipeline"

  puts system(%{bash -c "fly -t #{target_name} set-pipeline \
    -p #{PIPELINE_PREFIX}#{name} \
    -c #{config} \
    #{load.collect { |l| "-l #{l}" }.join(' ')}
  "})
end

def generate_full_path_for_concourse_vars_files(vars_files)
  vars_files_with_path = []
  vars_files.each do |var_file|
    if var_file =~ /versions.yml/
      vars_files_with_path << "#{PAAS_TEMPLATES}/#{var_file}"
    else
      vars_files_with_path << "#{SECRETS}/#{var_file}"
    end
  end
  vars_files_with_path
end

def update_bosh_lite_pipelines(target_name)
  header("For pipelines in #{PIPELINES_DIR}")
  depls=OPTIONS[:depls]
  Dir["#{PIPELINES_DIR}/*.yml"].each do |filename|
    # puts "Found #{filename}"
    next if OPTIONS.key?(:depls) && !filename.include?(OPTIONS[:depls])
    next if OPTIONS.key?(:template) && !filename.include?(OPTIONS[:template])
    puts "Processing only #{filename}"
    deployment_name = File.basename(filename, '.yml')
    ci_deployment_overview = YAML.load_file("#{SECRETS}/#{depls}/ci-deployment-overview.yml")

    pipelines=ci_deployment_overview['ci-deployment'][depls]['pipelines']
    current_pipeline = pipelines[deployment_name]
    if current_pipeline.nil?
      puts "invalid config #{SECRETS}/#{depls}/ci-deployment-overview.yml should contains a key ...[pipelines][vars_files]"
      puts "ignoring pipeline #{filename} (invalid config #{SECRETS}/#{depls}/ci-deployment-overview.yml)"
      next
    end
    vars_files_with_path = generate_full_path_for_concourse_vars_files(current_pipeline['vars_files'])
    set_pipeline(
      target_name: target_name,
      name: deployment_name,
      config: filename,
      load: vars_files_with_path
    )
  end
end


update_bosh_lite_pipelines target_name

