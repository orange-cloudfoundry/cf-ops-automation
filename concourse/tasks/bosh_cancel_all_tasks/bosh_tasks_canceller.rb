require 'json'
require 'fileutils'
require 'resolv'
require 'uri'
require 'open3'

# this class helps cancelling all processing BOSH task.
# TODO: export methods in module
class BoshTasksCanceller
  def execute
    self.class.cancel_tasks
  end

  class << self
    def cancel_tasks
      puts "NOTE: the BOSH Director can only cancel processing tasks."

      check_environment
      check_processing_tasks
      cancel_processing_tasks
    end

    def cancel_processing_tasks
      processing_tasks.each do |task|
        cancel_task_with_id task["id"]
      end
    end

    def check_processing_tasks
      puts "No processing tasks found" if processing_tasks.empty?
    end

    def processing_tasks
      tasks_table = extract_tasks_from_bosh_tasks_table(bosh_tasks)
      active_tasks = tasks_table.first["Rows"]
      active_tasks.keep_if { |task| task["state"] == "processing" }
    end

    def bosh_tasks
      @bosh_tasks ||=
        begin
          stdout, stderr, status = Open3.capture3(cmd_env, "bosh tasks --json")
          handle_bosh_cli_response(stdout, stderr, status)
          stdout
        end
    end

    def extract_tasks_from_bosh_tasks_table(tasks_table)
      JSON.parse(tasks_table)["Tables"].keep_if do |table|
        table["Content"] == "tasks"
      end
    end

    def cancel_task_with_id(task_id)
      puts "Cancelling task with Id `#{task_id}`."
      stdout, stderr, status = Open3.capture3(cmd_env, bosh_cancel_task_cmd(task_id))
      handle_bosh_cli_response(stdout, stderr, status)
    end

    def handle_bosh_cli_response(stdout, stderr, status)
      raise BoshCliError, "Stderr:\n#{stderr}\nStdout:\n#{stdout}" if (stderr != nil && stderr != "") || status.exitstatus != 0
    end

    def bosh_cancel_task_cmd(task_id)
      "bosh cancel-task #{task_id}"
    end

    def check_environment
      %w[BOSH_TARGET BOSH_CLIENT BOSH_CLIENT_SECRET BOSH_CA_CERT].each do |arg|
        check_env_var(arg)
      end

      error_msg = "The environment is missing env vars for this task to be able to work properly."
      raise EnvVarMissing, error_msg if File.exist?(error_filepath) && !File.read(error_filepath).empty?
    end

    def check_env_var(arg)
      return if ENV[arg] && !ENV[arg].empty?
      error_msg = "ERROR: missing environment variable: #{arg}"
      puts error_msg
      File.open(error_filepath, 'w+') { |file| file.write(error_msg) }
    end

    def error_filepath
      "result-dir/error.log"
    end

    # This method helps us adding BOSH_ENVIRONMENT to the shell environment
    def cmd_env
      @cmd_env ||=
        begin
          uri = ENV['BOSH_TARGET']
          return { "BOSH_ENVIRONMENT" => uri } if uri =~ Resolv::IPv4::Regex || uri =~ Resolv::IPv6::Regex

          host = URI(uri).host
          bosh_env = Resolv.getaddress(host)
          { "BOSH_ENVIRONMENT" => bosh_env }
        end
    end
  end

  class EnvVarMissing < RuntimeError; end
  class BoshCliError < RuntimeError; end
end
