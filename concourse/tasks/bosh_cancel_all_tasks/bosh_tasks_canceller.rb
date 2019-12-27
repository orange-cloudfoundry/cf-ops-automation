require 'json'
require 'fileutils'
require 'resolv'
require 'uri'
require 'open3'

# this class helps cancelling all processing BOSH task.
class BoshTasksCanceller
  def initialize(list_command = Tasks::Bosh::ListTasks.new, cancel_command = Tasks::Bosh::CancelTask.new)
    @list_tasks_holder = list_command
    @cancel_task_holder = cancel_command
  end

  def process
    puts "NOTE: the BOSH Director can only cancel processing or queued tasks."
    active_tasks = select_active_tasks
    puts "No active tasks found" if active_tasks.empty?
    cancel_processing_tasks(active_tasks)
  end

  private

  def select_active_tasks
    current_tasks = @list_tasks_holder.execute
    active_tasks = filter_active_tasks(current_tasks)
    puts "No active tasks found" if active_tasks.empty?
    active_tasks
  end

  def filter_active_tasks(tasks)
    return [] unless tasks

    tasks.dup.keep_if { |task| task["state"] == "processing" || task["state"] == "queued" }
  end

  def cancel_processing_tasks(active_tasks)
    active_tasks.each do |task|
      task_id = task&.dig("id")
      continue unless task_id
      puts "Cancelling task with Id `#{task_id}`."
      @cancel_task_holder.execute(task_id)
    end
  end

  class << self
    def error_filepath
      "result-dir/error.log"
    end
  end
end
