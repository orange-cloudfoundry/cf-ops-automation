module Tasks
  module Bosh
    # holds bosh list tasks command
    class ListTasks < Executor
      def execute
        result = self.class.run_command(bosh_command)
        filtered_result = self.class.filter_table_result(result, 'tasks')
        self.class.rows(filtered_result)
      end

      def bosh_command
        "bosh tasks --json"
      end
    end
  end
end
