#!/usr/bin/env ruby
# encoding: utf-8

task_root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..'))
require "#{task_root_dir}/cf-ops-automation/lib/ci_deployment"
ci_overview = CiDeployment.new(File.join(ENV.fetch('SECRETS_PATH', 'secrets'), '*-depls')).overview

result = CiDeployment.teams(ci_overview)

output_dir = 'ci-deployment-overview'.freeze

filename = File.join(output_dir, 'teams.yml')
Dir.mkdir output_dir unless Dir.exist?(File.dirname(filename))
File.open(filename, 'w') do |file|
  file.write result.to_yaml
  file.flush
end


