require_relative '../coa_logger'

module Coa
  module Utils
    module Concourse
      # Concourse's Builds concept: https://concourse-ci.org/builds.html
      class Build
        include Coa::Utils::CoaLogger

        FAILED_STATUS = %(failed errored aborted).freeze
        FINISHED_STATUS = %(failed succeeded errored aborted).freeze

        attr_reader :name, :status, :full_job_name

        def initialize(params)
          @name = params[:name]
          @status = params[:status]
          @full_job_name = params[:full_job_name]
        end

        def self.watch_job(full_job_name, max_retries, fly)
          logger.log_and_puts :info, "Watching job #{full_job_name}"
          retries = 0
          while retries < max_retries
            build = get_last_job_build(full_job_name, fly)
            sleep 1
            break if build.finished?
            retries += 1
          end
          build
        end

        def self.get_last_job_build(full_job_name, fly)
          raw_builds = fly.get_raw_job_builds(full_job_name)
          new_from_raw_builds(full_job_name, raw_builds)
        end

        def self.new_from_raw_builds(full_job_name, builds)
          build = builds.split("\n").max_by { |bd| bd.split[2] } # [2] contains an incremental id for the build
          split_build = build.split
          new(name: split_build[2], status: split_build[3], full_job_name: full_job_name)
        rescue NoMethodError => _
          new(name: full_job_name, status: "not started")
        end

        def handle_result(ignore_failure)
          log_final_status(ignore_failure)

          return unless unexpectedly_failed?(ignore_failure)

          logger.log_and_puts(:error, "Build failed.")
          exit 1
        end

        def log_final_status(ignore_failure)
          failure_ignored = failed? && ignore_failure
          logger.log_and_puts(:info, "Final status for job '#{full_job_name}': #{status}")
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
