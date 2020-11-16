require 'open3'
require 'tempfile'

require_relative './coa_logger'

module Coa
  module Utils
    # This class can execute system commands, more or less verbose, potential
    # while loading a profile. Will raise an error if the command fails unless
    # told otherwise.
    class CommandRunner
      include Coa::Utils::CoaLogger

      attr_reader :command, :fail_silently, :profile, :verbose

      def self.run_cmd(command, options = {})
        new(command, options).execute
      end

      def initialize(command, options = {})
        @command       = command
        @fail_silently = options[:fail_silently] == true
        @profile       = options[:profile].to_s
      end

      def execute
        write_header
        stdout, stderr, status = execute_command
        log_or_raise(stdout, stderr, status)
        stdout
      ensure
        profile && profile_tempfile&.unlink
      end

      private

      def write_header
        logger.debug("Running: `#{command}`")
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

      def log_or_raise(stdout, stderr, status)
        print_and_raise_error(stdout, stderr) unless status.success? || fail_silently
      end

      def print_and_raise_error(stdout, stderr)
        message = "Command `#{command}` errored with the following outputs.\nstderr:\n#{stderr}\nstdout:\n#{stdout}"
        logger.log_and_puts :error, message
        raise message
      end
    end
  end
end
