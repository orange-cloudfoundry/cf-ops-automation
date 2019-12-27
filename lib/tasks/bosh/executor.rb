module Tasks
  module Bosh
    require 'json'
    require 'fileutils'
    require 'resolv'
    require 'uri'
    require 'open3'

    BOSH_CONTENT = %w[tasks deployments].freeze

    # this class helps interacting with BOSH. It is a base class, with a child per bosh command
    class Executor
      def execute
        raise "Should be overridden !"
      end

      class << self
        def filter_table_result(bosh_command_output, bosh_content_filter = nil)
          if bosh_content_filter
            bosh_command_output&.dig("Tables")&.keep_if do |table|
              table["Content"] == bosh_content_filter
            end
          end
          bosh_command_output
        end

        def rows(table)
          table&.dig('Tables')&.first&.dig('Rows') || []
        end

        def run_command(bosh_command)
          check_environment
          stdout, stderr, status = Open3.capture3(cmd_env, bosh_command)
          handle_bosh_cli_response(stdout, stderr, status)
          JSON.parse(stdout)
        end

        def handle_bosh_cli_response(stdout, stderr, status)
          raise BoshCliError, "Stderr:\n#{stderr}\nStdout:\n#{stdout}" if (!stderr.nil? && !stderr.empty?) || status.exitstatus != 0
        end

        def check_environment
          %w[BOSH_TARGET BOSH_CLIENT BOSH_CLIENT_SECRET BOSH_CA_CERT].each do |arg|
            check_env_var(arg)
          end

          error_msg = "The environment is missing env vars for this task to be able to work properly."
          raise EnvVarMissing, error_msg if File.exist?(error_filepath) && !File.read(error_filepath).empty?
        end

        def check_env_var(arg)
          return if ENV[arg] && !ENV[arg].empty?

          error_msg = "ERROR: missing environment variable: #{arg}\n"
          puts "writing <#{error_msg}> to <#{error_filepath}"
          File.open(error_filepath, 'a') { |file| file.write(error_msg) }
        end

        def output_result_resource
          "result-dir"
        end

        def error_filepath
          File.join(output_result_resource, "error.log")
        end

        # This method helps us adding BOSH_ENVIRONMENT to the shell environment
        def cmd_env
          @cmd_env ||=
            begin
              uri = ENV['BOSH_TARGET']
              return { "BOSH_ENVIRONMENT" => uri } if uri =~ Resolv::IPv4::Regex || uri =~ Resolv::IPv6::Regex

              host = URI(uri).host
              bosh_env = Resolv.getaddress(host)
              { "BOSH_ENVIRONMENT" => bosh_env }
            end
        end
      end
    end
    class EnvVarMissing < RuntimeError; end
    class BoshCliError < RuntimeError; end
  end
end
