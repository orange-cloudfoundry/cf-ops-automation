require_relative '../command_runner'

module Coa
  module Utils
    module Concourse
      # This class serves as an interface to Concourse's CLI "fly".
      class Fly
        def initialize(target, creds)
          @target = target
          @creds = creds
          self.class.login(target, creds)
        end

        def self.login(target, creds)
          ca_cert_option, ca_cert = generate_ca_cert_option(creds.insecure, creds.ca_cert)
          command = "login --username #{creds.username} --password #{creds.password} --concourse-url #{creds.url} #{ca_cert_option} && fly --target #{target} sync"

          Coa::Utils::CommandRunner.
            new("fly --target #{target} #{command}", verbose: false).
            execute
        ensure
          ca_cert&.unlink
        end

        def self.generate_ca_cert_option(insecure, ca_cert)
          ca_cert_file = Tempfile.new

          if insecure == "true"
            ca_cert_option = "--insecure"
          else
            ca_cert_file.write(ca_cert)
            ca_cert_file.close
            ca_cert_option = "--ca-cert #{ca_cert_file.path}"
          end

          [ca_cert_option, ca_cert_file]
        end

        def destroy_pipelines(pipelines)
          pipelines.each_key do |pipeline|
            destroy_pipeline(pipeline)
          end
        end

        def destroy_pipeline(pipeline)
          run "destroy-pipeline --pipeline #{pipeline} --non-interactive"
        end

        def unpause_pipeline(pipeline)
          run "unpause-pipeline --pipeline #{pipeline}"
        end

        def pause_pipeline(pipeline)
          run "pause-pipeline --pipeline #{pipeline}"
        end

        def trigger_job(job)
          run "trigger-job --job #{job}"
        end

        def pause_job(job)
          run "pause-job --job #{job}"
        end

        def get_raw_job_builds(full_job_name)
          run "builds --job #{full_job_name}", verbose: false
        end

        def set_pipeline(pipeline, options)
          run "set-pipeline --pipeline #{pipeline} #{options} --non-interactive"
        end

        private

        def run(command, cmd_options = {})
          Coa::Utils::CommandRunner.
            new("fly --target #{@target} #{command}", cmd_options).
            execute
        end
      end
    end
  end
end
