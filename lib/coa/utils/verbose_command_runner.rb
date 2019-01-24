require 'open3'
require 'tempfile'

require_relative './coa_logger'

module Coa
  module Utils
    class VerboseCommandRunner < CommandRunner
      def log_or_raise(stdout, stderr, status)
        if status.success?
          print_success(stdout)
        elsif fail_silently
          print_ignored_error(stdout, stderr)
        else
          print_and_raise_error(stdout, stderr)
        end
      end

      def write_header
        suffix = fail_silently ? "while ignoring errors." : ""
        logger.log_and_puts :info, "Running: `#{executed_command}` #{suffix}"
      end

      def print_ignored_error(stdout, stderr)
        logger.log_and_puts :info, "Command `#{command}` errored, but continuing:\nstderr:\n#{stderr}\nstdout:\n#{stdout}"
      end

      def print_success(stdout)
        message = stdout.strip.empty? ? "Command `#{command}` ran successfully with no output" : "Command ran successfully with the following output:\n#{stdout}"
        logger.log_and_puts :info, message
      end
    end
  end
end
