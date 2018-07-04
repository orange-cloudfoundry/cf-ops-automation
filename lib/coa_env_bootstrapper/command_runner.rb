module CoaEnvBootstrapper
  module CommandRunner
    def run_cmd(cmd, opts = {})
      cmd = source_command(cmd, opts[:source_file_path]) if opts[:source_file_path]

      write_header(cmd, opts[:ignore_error])
      stdout, stderr, status = Open3.capture3(cmd)
      determine_sucess(stdout, stderr, status, opts[:ignore_error])

      stdout
    end

    def source_command(cmd, source_file_path)
      ". #{source_file_path} && #{cmd}"
    end

    def write_header(command, error_ignored)
      puts "Running: `#{command}`"
      puts "while ignoring errors." if error_ignored
    end

    def determine_sucess(stdout, stderr, status, error_ignored)
      if status.success?
        puts "Command ran succesfully with the following output.", stdout
      elsif error_ignored
        puts "Command errored, but continuing:", "stderr:", stderr, "stdout:", stdout
      else
        raise "Command errored with the following outputs.\nstderr:\n#{stderr}\nstdout:\n#{stdout}"
      end
      puts ""
    end
  end
end
