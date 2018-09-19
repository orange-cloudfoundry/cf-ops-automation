require 'json'
require 'fileutils'
require 'open3'

# this class helps bosh variables call.
class BoshVariablesExecutor
  def execute
    self.class.credential_fingerprints
  end

  class << self
    def credential_fingerprints
      check_environment
      execute_bosh_command
    end

    def execute_bosh_command
      stdout, stderr, status = Open3.capture3(%(bash -ec "source ./scripts-resource/scripts/bosh_cli_v2_login.sh ${BOSH_TARGET}; bosh variables --json > #{result_filepath}"))
      handle_bosh_cli_response(stdout, stderr, status)
    end

    def handle_bosh_cli_response(stdout, stderr, status)
      puts stdout
      puts "Exit status: #{status.exitstatus}"
      if !stderr.to_s.empty? || status.exitstatus != 0
        puts "Error log: <#{stderr}>"
        error_msg = "Stderr:\n#{stderr}\nStdout:\n#{stdout}"
        File.open(error_filepath, 'w+') { |file| file.write(error_msg) }
        raise BoshCliError, error_msg
      end
    end

    def check_environment
      %w[BOSH_TARGET BOSH_CLIENT BOSH_CLIENT_SECRET BOSH_CA_CERT BOSH_DEPLOYMENT].each do |arg|
        check_env_var(arg)
      end

      error_msg = "The environment is missing env vars for this task to be able to work properly."
      raise EnvVarMissing, error_msg if File.exist?(error_filepath) && !File.read(error_filepath).empty?
    end

    def check_env_var(arg)
      return if ENV[arg] && !ENV[arg].empty?
      error_msg = "ERROR: missing environment variable: #{arg}"
      puts error_msg
      File.open(error_filepath, 'w+') { |file| file.write(error_msg) }
    end

    def result_filepath
      "result-dir/credential_fingerprints.json"
    end

    def error_filepath
      "result-dir/error.log"
    end
  end

  # Class to handle error raised when an environment variable is missing
  class EnvVarMissing < RuntimeError; end
  # Class to handle error raised when calls to bosh CLI fail
  class BoshCliError < RuntimeError; end
end
