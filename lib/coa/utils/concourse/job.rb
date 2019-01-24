require_relative './build'
require_relative '../coa_logger'

module Coa
  module Utils
    module Concourse
      # This class represents Concourse's concept of a job:
      # https://concourse-ci.org/jobs.html
      class Job
        include Coa::Utils::CoaLogger

        attr_reader :config, :name, :pipeline

        def initialize(name:, config: {}, pipeline:)
          @name     = name
          @config   = config
          @pipeline = pipeline
        end

        def fullname
          "#{pipeline.name}/#{name}"
        end

        def getting_paused?
          config["pause"] == true
        end

        def getting_triggered?
          config["trigger"] == true
        end

        def ignore_failure?
          config["ignore-failure"] == true
        end

        def pause
          fly.pause_job(fullname)
        end

        def trigger
          fly.trigger_job(fullname)
        end

        def raw_builds
          fly.get_raw_job_builds(fullname)
        end

        def pause_if_asked
          pause if getting_paused?
        end

        def trigger_and_watch
          trigger if getting_triggered?

          logger.log_and_puts :info, "Watching job #{fullname}"
          build = Coa::Utils::Concourse::Build.new(job: self)
          build.watch(ignore_failure?)
        end

        def fly
          concourse = pipeline.concourse
          Fly.new(target: concourse.target, creds: concourse.creds, team: pipeline.team)
        end
      end
    end
  end
end
