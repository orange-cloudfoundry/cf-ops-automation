require_relative './fly_client'
require_relative './build'

module CoaConcourse
  # This class serves as an interface to Concourse. For the moment, it is
  # decoupled from Concourse's CLI "fly".
  class ConcourseClient
    include CoaLogger

    attr_reader :creds, :target

    def initialize(target, creds)
      @target = target
      @creds = creds
    end

    def set_pipeline(pipeline, options)
      fly_client.set_pipeline(pipeline, options)
    end

    def destroy_pipelines(pipelines)
      fly_client.destroy_pipelines(pipelines)
    end

    def unpause_pipeline(pipeline)
      fly_client.unpause_pipeline(pipeline)
    end

    def trigger_job(job)
      fly_client.trigger_job(job)
    end

    def pause_job(job)
      fly_client.pause_job(job)
    end

    def run_and_watch_pipelines(pipelines, max_retries = 1800)
      pipelines.each do |pl_name, pl_jobs|
        paused_jobs = pl_jobs.select { |_, options| options["pause"] }
        paused_jobs.each_key { |job_name| pause_job("#{pl_name}/#{job_name}") }

        fly_client.unpause_pipeline(pl_name)
        jobs_to_run = pl_jobs.delete_if { |_, options| options["pause"] }
        run_and_watch_jobs(jobs_to_run, pl_name, max_retries)
        fly_client.pause_pipeline(pl_name)
      end
    end

    private

    def fly_client
      FlyClient.new(target, creds)
    end

    def run_and_watch_jobs(pl_jobs, pl_name, max_retries)
      pl_jobs.each do |job_name, job_opts|
        full_job_name = "#{pl_name}/#{job_name}"
        run_and_watch_job(full_job_name, job_opts, max_retries)
      end
    end

    def run_and_watch_job(full_job_name, opts, max_retries)
      fly_client.trigger_job(full_job_name) if opts["trigger"] == true
      logger.log_and_puts :info, "Wathcing job #{full_job_name}"
      finished_build = CoaConcourse::Build.watch_job(full_job_name, max_retries, fly_client)
      finished_build.handle_result(opts["ignore-failure"])
    end
  end
end
