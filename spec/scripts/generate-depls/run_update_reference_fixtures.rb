require 'tmpdir'
require 'rspec'
require_relative 'test_helper'
require_relative '../../../lib/directory_initializer'
require 'fileutils'

formatter = RSpec::Core::Formatters::DocumentationFormatter.new(StringIO.new)
def formatter.stop(arg1); end

RSpec.configuration.reporter.register_listener(formatter, :message, :dump_summary, :dump_profile, :stop, :seed, :close, :start, :example_group_started)

def generated_pipeline_dir(pipelines_base_dir, test_type_prefix)
  File.join(pipelines_base_dir, "#{test_type_prefix}-tests", 'pipelines')
end

spec_name = File.basename(__FILE__, '.rb').delete_prefix("run_") + "_spec.rb"
puts "Running spec for #{spec_name}"
RSpec::Core::Runner.run([File.join(File.dirname(__FILE__), spec_name)])

puts formatter.output.string

pipelines_dir = File.join(File.dirname(__FILE__), 'fixtures', 'generated')
references_dir = File.join(File.dirname(__FILE__), 'fixtures', 'references')

raise "Invalid pipelines dir #{pipelines_dir}" unless Dir.exist?(pipelines_dir)
raise "Invalid references_dir #{references_dir}" unless Dir.exist?(references_dir)

puts "Coping generated files to reference"

puts "Processing Cf-Apps Pipelines"
FileUtils.cp("#{generated_pipeline_dir(pipelines_dir, 'apps')}/apps-depls-cf-apps-generated.yml", "#{references_dir}/apps-depls-cf-apps-ref.yml", verbose: true)

puts "Processing Delete Pipelines"
FileUtils.cp("#{generated_pipeline_dir(pipelines_dir, 'delete')}/delete-depls-bosh-generated.yml", "#{references_dir}/delete-depls-bosh-ref.yml", verbose: true)

puts "Processing Empty Pipelines"
FileUtils.cp("#{generated_pipeline_dir(pipelines_dir, 'empty')}/empty-depls-cf-apps-generated.yml", "#{references_dir}/empty-cf-apps.yml", verbose: true)
FileUtils.cp("#{generated_pipeline_dir(pipelines_dir, 'empty')}/empty-depls-bosh-generated.yml", "#{references_dir}/empty-depls.yml", verbose: true)
FileUtils.cp("#{generated_pipeline_dir(pipelines_dir, 'empty')}/empty-depls-bosh-precompile-generated.yml", "#{references_dir}/empty-bosh-precompile.yml", verbose: true)
FileUtils.cp("#{generated_pipeline_dir(pipelines_dir, 'empty')}/shared-concourse-generated.yml", "#{references_dir}/empty-shared-concourse.yml", verbose: true)
FileUtils.cp("#{generated_pipeline_dir(pipelines_dir, 'empty')}/shared-k8s-generated.yml", "#{references_dir}/empty-shared-k8s.yml", verbose: true)
FileUtils.cp("#{generated_pipeline_dir(pipelines_dir, 'empty')}/shared-update-generated.yml", "#{references_dir}/empty-shared-update.yml", verbose: true)

puts "Processing Simple Pipelines"
FileUtils.cp("#{generated_pipeline_dir(pipelines_dir, 'simple')}/simple-depls-bosh-generated.yml", "#{references_dir}/simple-depls-bosh-ref.yml", verbose: true)
FileUtils.cp("#{generated_pipeline_dir(pipelines_dir, 'simple')}/simple-depls-bosh-precompile-generated.yml", "#{references_dir}/simple-depls-bosh-precompile-ref.yml", verbose: true)

puts "Processing Shared"
FileUtils.cp("#{generated_pipeline_dir(pipelines_dir, 'simple')}/shared-concourse-generated.yml", "#{references_dir}/simple-shared-concourse.yml", verbose: true)
FileUtils.cp("#{generated_pipeline_dir(pipelines_dir, 'simple')}/shared-k8s-generated.yml", "#{references_dir}/simple-shared-k8s.yml", verbose: true)
FileUtils.cp("#{generated_pipeline_dir(pipelines_dir, 'simple')}/shared-update-generated.yml", "#{references_dir}/simple-shared-update.yml", verbose: true)


FileUtils.rm_rf(pipelines_dir)
