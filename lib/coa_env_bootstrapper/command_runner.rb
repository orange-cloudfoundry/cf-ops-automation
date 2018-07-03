module CoaEnvBootstrapper
  class CommandRunner
    def initialize(coa_env_bootstrapper)
      @ceb = coa_env_bootstrapper
    end

    def run(cmd, opts = {})
      puts "Running: #{cmd}"
      puts "with options: #{opts.inspect}"

      cmd_to_exectute = opts[:sourced] ? ". #{ceb.source_file} && #{cmd}" : cmd
      stdout, stderr, status = Open3.capture3(cmd_to_exectute)

      if status.success?
        puts "Command ran succesfully with output:", stdout
      else
        if opts[:ignore_error]
          puts "Command errored, but continuing:", "stderr:", stderr, "stdout:", stdout
        else
          fail "Command errored with outputs:\nstderr:\n#{stderr}\nstdout:\n#{stdout}"
        end
      end
      puts ""

      stdout
    end
  end
end
