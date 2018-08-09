require 'json'
require 'fileutils'
require 'resolv'
# this class helps cancelling all processing BOSH task.
class BoshTasksCanceller
  def execute
    self.class.cancel_tasks
  end

  class << self
    def cancel_tasks
      puts "NOTE: the BOSH Director can only cancel processing tasks."

      # check_environment
      # puts `#{bosh_login_cmd}`
      puts `cat /etc/resolv.conf`
      puts `ping -c 3 bosh-master.internal.paas`
      puts "google: #{Resolv::DNS.new.getaddress('www.google.com')}"
      puts "bosh-master: #{Resolv::DNS.new.getaddress('bosh-master.internal.paas')}"
      puts "IP: #{Resolv::DNS.new.getaddress('192.168.116.158')}"
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
      tasks_table = JSON.parse(bosh_tasks)["Tables"].keep_if do |table|
        table["Content"] == "tasks"
      end
      active_tasks = tasks_table.first["Rows"]
      active_tasks.keep_if { |task| task["state"] == "processing" }
    end

    def bosh_tasks
      @bosh_tasks ||= `bosh tasks --json`
    end

    def cancel_task_with_id(task_id)
      puts "Cancelling task with Id `#{task_id}`."

      `#{bosh_cancel_task_cmd(task_id)}`
    end

    def bosh_cancel_task_cmd(task_id)
      "bosh cancel-task #{task_id}"
    end

    # def bosh_login_cmd
    #   login_log_filename = "result-dir/login.log"
    #   "./scripts-resource/scripts/bosh_cli_v2_login.sh #{ENV['BOSH_ENVIRONMENT']} | tee -a #{login_log_filename}"
    # end

    def check_environment
      error_filepath = "result-dir/error.log"

      %w[BOSH_ENVIRONMENT BOSH_CLIENT BOSH_CLIENT_SECRET BOSH_CA_CERT].each do |arg|
        check_env_var(arg)
      end

      raise "The environment is missing env vars for this task to be able to work properly." if File.exist?(error_filepath)
    end

    def check_env_var(arg)
      return unless ENV[arg].empty?
      err_msg = "ERROR: missing environment variable: #{arg}"
      puts err_msg
      File.open(error_filepath, 'w+') { |file| file.write(err_msg) }
    end
  end
end
