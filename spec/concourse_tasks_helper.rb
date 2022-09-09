require 'tmpdir'
require 'yaml'

class ConcourseTaskHelper
  attr_reader :additional_dirs, :secrets_dir, :templates_dir, :result_dir

  # alias

  # @param [Array] additional_dirs_name
  def initialize(skip_secrets: false, skip_templates: false, skip_reference: false, skip_result_dir: false, additional_dirs_name: [])
    @additional_dirs = {}
    @secrets_dir = Dir.mktmpdir unless skip_secrets
    @templates_dir = Dir.mktmpdir unless skip_templates
    @reference_resource = Dir.mktmpdir unless skip_reference
    @result_dir = Dir.mktmpdir unless skip_result_dir
    additional_dirs_name.each { |name| additional_dirs[name] = Dir.mktmpdir }
  end

  def cleanup
    [@secrets_dir, @templates_dir,@reference_resource].each {|a_dir| FileUtils.rm_rf a_dir if a_dir && Dir.exist?(a_dir) }
    @additional_dirs.each { |a_dir| FileUtils.rm_rf a_dir if Dir.exist?(a_dir) }
  end
end
