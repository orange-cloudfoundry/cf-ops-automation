require_relative './fly'
require_relative './build'

module Coa
  module Utils
    module Concourse
      # This class serves as an interface to Concourse. For the moment, it is
      # decoupled from Concourse's CLI "fly".
      class Client
        include Coa::Utils::CoaLogger

        attr_reader :creds, :target, :fly

        def initialize(target, creds)
          @target = target
          @creds = creds
          @fly = Fly.new(target, creds)
        end

        def set_pipeline(pipeline, options)
          fly.set_pipeline(pipeline, options)
        end

        def destroy_pipelines(pipelines)
          fly.destroy_pipelines(pipelines)
        end

        def unpause_pipeline(pipeline)
          fly.unpause_pipeline(pipeline)
        end

        def trigger_job(job)
          fly.trigger_job(job)
        end

        def pause_job(job)
          fly.pause_job(job)
        end

        def run_and_watch_pipelines(pipelines, max_retries = 1800)
          pipelines.each do |pl_name, pl_jobs|
            paused_jobs = pl_jobs.select { |_, options| options["pause"] }
            paused_jobs.each_key { |job_name| pause_job("#{pl_name}/#{job_name}") }

            fly.unpause_pipeline(pl_name)
            jobs_to_run = pl_jobs.delete_if { |_, options| options["pause"] }
            run_and_watch_jobs(jobs_to_run, pl_name, max_retries)
            fly.pause_pipeline(pl_name)
          end
        end

        private

        def run_and_watch_jobs(pl_jobs, pl_name, max_retries)
          pl_jobs.each do |job_name, job_opts|
            full_job_name = "#{pl_name}/#{job_name}"
            run_and_watch_job(full_job_name, job_opts, max_retries)
          end
        end

        def run_and_watch_job(full_job_name, opts, max_retries)
          fly.trigger_job(full_job_name) if opts["trigger"] == true
          finished_build = Concourse::Build.watch_job(full_job_name, max_retries, fly)
          finished_build.handle_result(opts["ignore-failure"])
        end
      end
    end
  end
end
