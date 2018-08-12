require_relative '../coa_command_runner'

module CoaConcourse
  # This class serves as an interface to Concourse's CLI "fly".
  class FlyClient
    attr_reader :target, :creds

    def initialize(target, creds)
      @target = target
      @creds = creds
    end

    def login
      ca_cert_option, ca_cert = generate_ca_cert_option

      fly "login --username #{creds['username']} --password #{creds['password']} --concourse-url #{creds['url']} #{ca_cert_option} && fly --target #{target} sync",
          false, verbose: false
    ensure
      ca_cert&.unlink
    end

    def destroy_pipelines(pipelines)
      pipelines.each_key do |pipeline|
        destroy_pipeline(pipeline)
      end
    end

    def destroy_pipeline(pipeline)
      fly "destroy-pipeline --pipeline #{pipeline} --non-interactive", true
    end

    def unpause_pipeline(pipeline)
      fly "unpause-pipeline --pipeline #{pipeline}", true
    end

    def pause_pipeline(pipeline)
      fly "pause-pipeline --pipeline #{pipeline}", true
    end

    def trigger_job(job)
      fly "trigger-job --job #{job}", true
    end

    def pause_job(job)
      fly "pause-job --job #{job}", true
    end

    def get_raw_job_builds(full_job_name)
      fly "builds --job #{full_job_name}", true, verbose: false
    end

    def set_pipeline(pipeline, options)
      fly "set-pipeline --pipeline #{pipeline} #{options} --non-interactive", true
    end

    private

    def fly(command, need_login, cmd_options = {})
      login if need_login
      CoaCommandRunner.new("fly --target #{target} #{command}", cmd_options).execute
    end

    def generate_ca_cert_option
      ca_cert = Tempfile.new

      if creds["insecure"].to_s == "true"
        ca_cert_option = "--insecure"
      else
        ca_cert.write(creds['ca_cert'])
        ca_cert.close
        ca_cert_option = "--ca-cert #{ca_cert.path}"
      end

      [ca_cert_option, ca_cert]
    end
  end
end
