require_relative './pipeline'
require_relative './job'

module Coa
  module Utils
    module Concourse
      # This class serves as an interface to Concourse.
      class Concourse
        attr_reader :creds, :target

        def initialize(target, creds)
          @target = target
          @creds = creds
        end

        def set_pipeline(name:, options:, team: "main")
          Coa::Utils::Concourse::Pipeline.
            new(name: name, team: team, concourse: self).
            set(options)
        end

        def destroy_pipelines(pipelines)
          Coa::Utils::Concourse::Pipeline.destroy(pipelines, self)
        end

        def unpause_pipeline(name:, team: "main")
          Coa::Utils::Concourse::Pipeline.
            new(name: name, team: team, concourse: self).
            unpause
        end

        def trigger_job(name:, pipeline_name:, team: "main")
          pipeline = Coa::Utils::Concourse::Pipeline.
            new(name: pipeline_name, team: team, concourse: self)
          Coa::Utils::Concourse::Job.new(name: name, pipeline: pipeline).trigger
        end

        def pause_job(name:, pipeline_name:, team: "main")
          pipeline = Coa::Utils::Concourse::Pipeline.
            new(name: pipeline_name, team: team, concourse: self)
          Coa::Utils::Concourse::Job.new(name: name, pipeline: pipeline).pause
        end

        def unpause_and_watch_pipelines(pipelines)
          Coa::Utils::Concourse::Pipeline.unpause_and_watch(pipelines, self)
        end
      end
    end
  end
end
