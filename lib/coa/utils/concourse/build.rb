require_relative '../coa_logger'

module Coa
  module Utils
    module Concourse
      require 'json'
      # Concourse's Builds concept: https://concourse-ci.org/builds.html
      class Build
        include Coa::Utils::CoaLogger

        FAILED_STATUS = %(failed errored aborted).freeze
        FINISHED_STATUS = %(failed succeeded errored aborted).freeze
        MAX_RETRIES = 600

        attr_reader :job
        attr_accessor :status

        def initialize(job:, status: 'unknow')
          @job    = job
          @status = status
        end

        def watch(ignore_failure)
          follow_to_completion
          handle_result(ignore_failure)
        end

        def follow_to_completion
          retries = 0
          while retries < MAX_RETRIES
            update_status
            sleep 1
            break if finished?

            retries += 1
          end
        end

        def handle_result(ignore_failure)
          log_final_status(ignore_failure)
          return unless unexpectedly_failed?(ignore_failure)

          logger.log_and_puts(:info, job.watch)
          job.pipeline.pause
          logger.log_and_puts(:error, "The build has failed.")
          exit 1
        end

        private

        def update_status
          raw_builds = job.raw_builds
          update_status_from_raw_builds(raw_builds)
        end

        def update_status_from_raw_builds(raw_builds)
          builds = JSON.parse(raw_builds)
          latest_build = builds.max_by { |build| build['id'] }
          self.status = latest_build['status']
        rescue NoMethodError => _e # this would indicate that the build is not listed
          logger.debug "The build has probably not started yet."
        end

        def log_final_status(ignore_failure)
          failure_ignored = failed? && ignore_failure
          logger.log_and_puts(:info, "Final status for job '#{job.fullname}': #{status}")
          logger.log_and_puts(:info, "Timeout.") if status == "pending"
          logger.log_and_puts(:info, "Failure ignored for this job.") if failure_ignored
        end

        def finished?
          FINISHED_STATUS.include? status
        end

        def failed?
          FAILED_STATUS.include? status
        end

        def unexpectedly_failed?(ignore_failure)
          failed? && !ignore_failure || !finished?
        end
      end
    end
  end
end
