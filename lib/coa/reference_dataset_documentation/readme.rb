require_relative './file_list_writer'
require_relative './pipeline_list_writer'
require_relative './tree_writer'
require_relative './utils_writer'

module Coa
  module ReferenceDatasetDocumentation
    # This class represents a root deployment Readme.
    class Readme
      attr_reader :docs_config

      def initialize(docs_config)
        @docs_config = docs_config
      end

      def rewrite_scructure_documentation
        utils_writer.cleanup_readme
        utils_writer.write_intro
        tree_writer.write
        file_list_writer.write(
          config_repo_name:   docs_config.config_repo_name,
          template_repo_name: docs_config.template_repo_name
        )
      end

      def write_pipeline_documentation
        pipeline_list_writer.write
      end

      def utils_writer
        Coa::ReferenceDatasetDocumentation::UtilsWriter.new(docs_config)
      end

      def tree_writer
        Coa::ReferenceDatasetDocumentation::TreeWriter.new(docs_config)
      end

      def file_list_writer
        Coa::ReferenceDatasetDocumentation::FileListWriter.new(docs_config)
      end

      def pipeline_list_writer
        Coa::ReferenceDatasetDocumentation::PipelineListWriter.new(docs_config)
      end
    end
  end
end
