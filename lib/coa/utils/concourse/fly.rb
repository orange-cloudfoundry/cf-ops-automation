require_relative '../command_runner'

module Coa
  module Utils
    module Concourse
      # This class serves as an interface to Concourse's CLI "fly".
      class Fly
        def initialize(target:, creds:, team: 'main')
          @target = target
          self.class.login(target: target, creds: creds, team: team)
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
          run "builds --job #{full_job_name}"
        end

        def set_pipeline(pipeline, options)
          run "set-pipeline --pipeline #{pipeline} #{options} --non-interactive"
        end

        class << self
          def login(target:, creds:, team: 'main')
            ca_cert_option, ca_cert = creds.insecure? ? insecure_ca_cert_option : secure_ca_cert_option(creds.ca_cert)
            command = "login --team-name #{team} --username #{creds.username} --password #{creds.password} --concourse-url #{creds.url} #{ca_cert_option} && fly --target #{target} sync"

            Coa::Utils::CommandRunner.new("fly --target #{target} #{command}").execute
          ensure
            ca_cert&.unlink
          end

          def insecure_ca_cert_option
            ["--insecure", nil]
          end

          def secure_ca_cert_option(ca_cert)
            ca_cert_file = Tempfile.new
            ca_cert_file.write(ca_cert)
            ca_cert_file.close

            ca_cert_option = "--ca-cert #{ca_cert_file.path}"

            [ca_cert_option, ca_cert_file]
          end
        end

        private

        def run(command)
          Coa::Utils::CommandRunner.
            new("fly --target #{@target} #{command}").
            execute
        end
      end
    end
  end
end
