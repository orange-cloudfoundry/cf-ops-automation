module Tasks
  module Bosh
    # holds bosh cancel task command
    class CancelTask < Executor
      def execute(task_id)
        bosh_command = "bosh cancel-task --json --non-interactive #{task_id}"
        self.class.run_command(bosh_command)
      end
    end
  end
end
