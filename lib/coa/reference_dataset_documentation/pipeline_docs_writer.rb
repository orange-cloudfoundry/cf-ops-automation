require_relative './readme_author'

module Coa
  module ReferenceDatasetDocumentation
    # This class can write a list of credentials per pipeline and a list of
    # pipeline per credentials.
    class PipelineDocsWriter
      include Coa::ReferenceDatasetDocumentation::ReadmeAuthor

      def perform
        write_credentials_pipeline_list
        write_pipelines_credential_list
      end

      def write_credentials_pipeline_list
        write "## List of pipelines in which credentials appear for #{root_deployment_name}", ""

        credentials_pipeline_list.sort.each do |credential, pipelines|
          write_credential_pipeline_list(credential, pipelines)
        end
      end

      def write_pipelines_credential_list
        write "## Required pipeline credentials for #{root_deployment_name}", ""

        pipelines_credential_list.sort.each do |pipeline_name, pipe_creds|
          write_pipeline_credential_list(pipeline_name, pipe_creds)
        end
      end

      private

      def write_pipeline_credential_list(pipeline_name, pipe_creds)
        write("### #{pipeline_name}", "")

        if pipe_creds.empty?
          write("No credentials required", "")
        else
          pipe_creds.sort.each { |cred| write("* #{cred}") }
          write ""
        end
      end

      def write_credential_pipeline_list(credential, pipelines)
        write("### #{credential}", "")

        pipelines.uniq.sort.each { |pipeline| write("* #{pipeline}") }
        write ""
      end

      def pipelines_credential_list
        @pipelines_credential_list ||=
          begin
            pipe_creds = {}

            pipelines.generated_pipeline_paths.each do |path|
              pipeline_content = File.read(path)
              creds_list = pipeline_content.scan(/\(\(([\w|-]*)\)\)/).flatten.uniq
              pipeline_name = File.basename(path)
              pipe_creds[pipeline_name] = creds_list
            end

            pipe_creds
          end
      end

      def credentials_pipeline_list
        creds_pipe_list = Hash.new { |h, k| h[k] = [] }

        pipelines_credential_list.each do |pipeline_name, pipe_creds|
          pipe_creds.each do |cred|
            creds_pipe_list[cred] << pipeline_name
          end
        end

        creds_pipe_list
      end
    end
  end
end
