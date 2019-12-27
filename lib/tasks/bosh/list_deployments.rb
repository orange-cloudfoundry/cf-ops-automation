module Tasks
  module Bosh
    # holds bosh list deployments command
    class ListDeployments < Executor
      def execute
        result = self.class.run_command(bosh_command)
        raw_deployments = self.class.rows(result)
        raw_deployments&.map { |deployment| deployment&.dig('name') }
      end

      def bosh_command
        "bosh deployments --json"
      end
    end
  end
end
