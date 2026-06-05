require_relative './job'
require_relative './fly'

module Coa
  module Utils
    module Concourse
      # This class represents Concourse's concept of a pipeline:
      # https://concourse-ci.org/pipelines.html
      class Pipeline
        attr_reader :concourse, :name, :team
        attr_accessor :jobs

        def initialize(name:, concourse:, team: "main")
          @name      = name
          @team      = team
          @concourse = concourse
          @jobs      = []
        end

        def unpause_and_watch
          unpause
          trigger_and_watch_jobs
          pause
        end

        def pause
          fly.pause_pipeline(name)
        end

        def unpause
          fly.unpause_pipeline(name)
        end

        def set(options)
          fly.set_pipeline(name, options)
        end

        def destroy(options)
          fly.destroy_pipeline(name, options)
        end

        def trigger_and_watch_jobs
          jobs_to_run = jobs.delete_if(&:getting_paused?)
          jobs_to_run.each(&:trigger_and_watch)
        end

        def pause_jobs
          jobs.each(&:pause_if_asked)
        end

        class << self
          def unpause_and_watch(pipeline_list, concourse)
            pipeline_list.each do |name, attributes|
              pipeline = new_from_hash(name: name, attributes: attributes, concourse: concourse)
              pipeline.pause_jobs
              pipeline.unpause_and_watch
            end
          end

          def destroy(pipeline_list, concourse)
            pipeline_list.each do |name, attributes|
              pipeline = new_from_hash(name: name, attributes: attributes, concourse: concourse)
              pipeline.destroy(fail_silently: true)
            end
          end

          def new_from_hash(name:, attributes: {}, concourse:)
            team = attributes["team"]
            pipeline = new(name: name, team: team, concourse: concourse)

            jobs = attributes["jobs"].map do |job_name, job_config|
              Coa::Utils::Concourse::Job.
                new(name: job_name, config: job_config, pipeline: pipeline)
            end
            pipeline.jobs = jobs

            pipeline
          end
        end

        private

        def fly
          Fly.new(target: concourse.target, creds: concourse.creds, team: team)
        end
      end
    end
  end
end
