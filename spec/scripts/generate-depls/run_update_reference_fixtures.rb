require 'tmpdir'
require 'rspec'
require_relative 'test_helper'
require_relative '../../../lib/directory_initializer'
require 'fileutils'

formatter = RSpec::Core::Formatters::DocumentationFormatter.new(StringIO.new)
def formatter.stop(arg1); end

RSpec.configuration.reporter.register_listener(formatter, :message, :dump_summary, :dump_profile, :stop, :seed, :close, :start, :example_group_started)

spec_name = File.basename(__FILE__, '.rb').delete_prefix("run_") + "_spec.rb"
puts "Running spec for #{spec_name}"
RSpec::Core::Runner.run([File.join(File.dirname(__FILE__), spec_name)])

puts formatter.output.string

pipelines_dir = File.join(File.dirname(__FILE__), 'fixtures', 'pipelines')
references_dir = File.join(File.dirname(__FILE__), 'fixtures', 'references')

raise "Invalid pipelines dir #{pipelines_dir}" unless Dir.exist?(pipelines_dir)
raise "Invalid references_dir #{references_dir}" unless Dir.exist?(references_dir)

puts "Coping generated files to reference"

puts "Processing Cf-Apps Pipelines"
FileUtils.cp("#{pipelines_dir}/apps-depls-cf-apps-generated.yml", "#{references_dir}/apps-depls-cf-apps-ref.yml", verbose: true)

puts "Processing Delete Pipelines"
FileUtils.cp("#{pipelines_dir}/delete-depls-bosh-generated.yml", "#{references_dir}/delete-depls-bosh-ref.yml", verbose: true)

puts "Processing Empty Pipelines"
FileUtils.cp("#{pipelines_dir}/empty-depls-cf-apps-generated.yml", "#{references_dir}/empty-cf-apps.yml", verbose: true)
FileUtils.cp("#{pipelines_dir}/empty-depls-concourse-generated.yml", "#{references_dir}/empty-concourse.yml", verbose: true)
FileUtils.cp("#{pipelines_dir}/empty-depls-bosh-generated.yml", "#{references_dir}/empty-depls.yml", verbose: true)
FileUtils.cp("#{pipelines_dir}/empty-depls-bosh-precompile-generated.yml", "#{references_dir}/empty-bosh-precompile.yml", verbose: true)
FileUtils.cp("#{pipelines_dir}/empty-depls-news-generated.yml", "#{references_dir}/empty-news.yml", verbose: true)
FileUtils.cp("#{pipelines_dir}/empty-depls-k8s-generated.yml", "#{references_dir}/empty-k8s.yml", verbose: true)

puts "Processing Simple Pipelines"
FileUtils.cp("#{pipelines_dir}/simple-depls-bosh-generated.yml", "#{references_dir}/simple-depls-bosh-ref.yml", verbose: true)
FileUtils.cp("#{pipelines_dir}/simple-depls-bosh-precompile-generated.yml", "#{references_dir}/simple-depls-bosh-precompile-ref.yml", verbose: true)
FileUtils.cp("#{pipelines_dir}/simple-depls-news-generated.yml", "#{references_dir}/simple-depls-news-ref.yml", verbose: true)
FileUtils.cp("#{pipelines_dir}/simple-depls-k8s-generated.yml", "#{references_dir}/simple-depls-k8s-ref.yml", verbose: true)

FileUtils.rm_rf(pipelines_dir)
