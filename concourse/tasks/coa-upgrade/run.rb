#!/usr/bin/env ruby
require 'fileutils'
require 'open3'

# Upgrade scripts launcher: it executes all migration scripts present in a directory
class CoaUpgrade
  UNDEFINED = 'Undefined'.freeze
  STDOUT_LOG_FILENAME = 'stdout.log'.freeze
  STDERR_LOG_FILENAME = 'stderr.log'.freeze

  def initialize(root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..')))
    @coa_root_dir = File.join(root_dir, 'cf-ops-automation')
    @config_root_dir = File.join(root_dir, 'config')
    @templates_root_dir = File.join(root_dir, 'templates')

    init_output_dir(root_dir)
  end

  def self.write(filename, data)
    File.open(filename, 'a') { |file| file.write data }
  end

  def self.list_migration_scripts(base_dir)
    Dir[File.join(base_dir, '*')]&.sort
  end

  def self.format_result(script_name, header, data)
    return '' if data.empty?

    result = "##################\n"
    result << "#{script_name} #{header}:\n"
    result << data
    result
  end

  def self.coa_version
    version = ENV.fetch('COA_VERSION', UNDEFINED)
    return UNDEFINED if version.empty?

    version
  end

  def migrate
    migration_scripts_path = locate_migration_scripts
    puts "searching migration scripts at '#{migration_scripts_path}'"
    migration_scripts = self.class.list_migration_scripts(migration_scripts_path)
    migration_scripts&.each do |script|
      puts "processing #{script.gsub(%r{^.*cf-ops-automation/}, '')}"
      execute_and_display(script)
    end
    dump_outputs
  end

  def stdout_filename
    File.join(@upgraded_results_dir, STDOUT_LOG_FILENAME)
  end

  def stderr_filename
    File.join(@upgraded_results_dir, STDERR_LOG_FILENAME)
  end

  private

  def write_stdout(data)
    self.class.write(stdout_filename, data)
  end

  def write_stderr(data)
    self.class.write(stderr_filename, data)
  end

  def execute_and_display(script)
    out, err = execute_upgrade_command(script)
    write_stdout(out)
    write_stderr(err)
  end

  def dump_outputs
    puts File.read(stdout_filename)
  end

  def locate_migration_scripts
    location = File.join(@coa_root_dir, 'upgrade', "v#{self.class.coa_version}")
    raise "No migration scripts found at #{location}" unless File.exist?(location)

    location
  end

  def execute_upgrade_command(script)
    upgrade_cmd = "#{script} -c #{@upgraded_config_root_dir} -t #{@upgraded_templates_root_dir}"
    out, err = Open3.capture3(upgrade_cmd)
    out_result = self.class.format_result(script, 'STDOUT', out)
    err_result = self.class.format_result(script, 'STDERR', err)
    [out_result, err_result]
  end

  def init_output_dir(root_dir)
    @upgraded_results_dir = File.join(root_dir, 'upgrade-results')
    @upgraded_config_root_dir = File.join(root_dir, 'upgraded-config')
    @upgraded_templates_root_dir = File.join(root_dir, 'upgraded-templates')
    FileUtils.cp_r(File.join(@config_root_dir, '.'), @upgraded_config_root_dir)
    FileUtils.cp_r(File.join(@templates_root_dir, '.'), @upgraded_templates_root_dir)
  end
end

CoaUpgrade.new.migrate
