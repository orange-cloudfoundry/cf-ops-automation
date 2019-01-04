require 'open3'
require 'tempfile'

require_relative './coa_logger'

# This class can execute system commands, more or less verbose, potential while
# loading a profile. Will raise an error if the comand fails unless told
# otherwise.
module Coa
  module Utils
    class CommandRunner
      include Coa::Utils::CoaLogger

      attr_reader :command, :fail_silently, :profile, :verbose

      def self.run_cmd(command, options = {})
        logger.info "pumpetup"
        new(command, options).execute
      end

      def initialize(command, options = {})
        @command       = command
        @fail_silently = !!options[:fail_silently]
        @profile       = options[:profile].to_s
        @verbose       = !!options[:verbose]
      end

      def execute
        write_header
        stdout, stderr, status = execute_command
        determine_success(stdout, stderr, status)
        stdout
      ensure
        profile && profile_tempfile&.unlink
      end

      private

      def write_header
        verbose ? write_verbose_header : logger.debug("Running: `#{command}`")
      end

      def execute_command
        Open3.capture3(executed_command)
      end

      def executed_command
        @executed_command ||= profile.empty? ? command : sourced_command
      end

      def sourced_command
        ". #{profile_tempfile.path} && #{command}"
      end

      def profile_tempfile
        @profile_tempfile ||=
          begin
            profile_file = Tempfile.new('.profile')
            profile_file.write(profile)
            profile_file.close
            profile_file
          end
      end

      def write_verbose_header
        suffix = fail_silently ? "while ignoring errors." : ""
        logger.log_and_puts :info, "Running: `#{executed_command}` #{suffix}"
      end

      def determine_success(stdout, stderr, status)
        if status.success?
          print_success(stdout) if verbose
        elsif fail_silently
          print_ignored_error(stdout, stderr) if verbose
        else
          print_and_raise_error(stdout, stderr)
        end
      end

      def print_success(stdout)
        message = stdout.strip.empty? ? "Command `#{command}` ran successfully with no output" : "Command ran successfully with the following output:\n#{stdout}"
        logger.log_and_puts :info, message
      end

      def print_ignored_error(stdout, stderr)
        logger.log_and_puts :info, "Command `#{command}` errored, but continuing:\nstderr:\n#{stderr}\nstdout:\n#{stdout}"
      end

      def print_and_raise_error(stdout, stderr)
        message = "Command `#{command}` errored with the following outputs.\nstderr:\n#{stderr}\nstdout:\n#{stdout}"
        logger.log_and_puts :error, message
        raise message
      end
    end
  end
end
