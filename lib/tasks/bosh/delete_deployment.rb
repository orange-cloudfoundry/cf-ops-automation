module Tasks
  module Bosh
    # holds bosh delete deployment command
    class DeleteDeployment < Executor
      def execute(name)
        bosh_command = "bosh delete-deployment --json --non-interactive -d #{name} --force"
        self.class.run_command(bosh_command)
      end
    end
  end
end
