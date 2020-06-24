require_relative './readme_author'

module Coa
  module ReferenceDatasetDocumentation
    # This class is useful for the readme to do actions unrelated to pipelines
    # or to the config and template files.
    class UtilsWriter
      include Coa::ReferenceDatasetDocumentation::ReadmeAuthor

      def cleanup_readme
        File.open(readme_path, 'w') { |file| file.write "" }
      end

      def write_intro
        write("# Directory structure '#{root_deployment_name}' for  example", "")
      end
    end
  end
end
