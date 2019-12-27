#!/usr/bin/env ruby

require 'yaml'
require 'tempfile'
require_relative '../../lib/coa'

manifests_filename = ARGV[0]
manifests = YAML.load_file(manifests_filename)&.dig('bosh', 'manifests')
raise "Invalid manifests format. Expected format: bosh.manifests.<deployment-name> = manifest-to-deploy" unless manifests

bosh_authentication_info_file = "prereqs/integration-test-prereqs.yml"
prerequisites = Coa::EnvBootstrapper::Prereqs.new_from_paths([bosh_authentication_info_file])
config_source = prerequisites.bosh
raise "Invalid bosh prerequisite" unless config_source

bosh_config = Coa::Utils::Bosh::Config.new(config_source)
bosh = Coa::EnvBootstrapper::Bosh.new(bosh_config)
manifests.each do |deployment_name, raw_manifest|
  puts "Ready to deploy #{deployment_name}"
  deployment_manifest_path = Tempfile.create(deployment_name)
  File.open(deployment_manifest_path, 'w+') { |file| file.write(YAML.dump(raw_manifest)) }
  puts "Created bosh manifest at #{deployment_manifest_path.path}"
  bosh.client.deploy(deployment_name, deployment_manifest_path.path)
  File.unlink(deployment_manifest_path)
end
