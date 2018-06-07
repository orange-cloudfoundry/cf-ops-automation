module ReferenceDatasetDocumentation
  module Helpers
    module FileListWriterHelpers
      def pretty_filepath(path, repo_name)
        stripped_path = path.strip
        filename = File.basename(stripped_path)
        return "" if filename[0] == "."
        prefix = extract_prefix(stripped_path)
        cleaned_path = clean_path(stripped_path)
        "#{prefix}* [#{filename}](/docs/reference_dataset/#{repo_name}/#{@generator.example_type}/#{@generator.root_deployment_name}/#{cleaned_path})"
      end

      def extract_prefix(path)
        path_items = path.strip.split('/')
        "  " * (path_items.size - 2)
      end

      def clean_path(path)
        path.strip.gsub(%r{^.\/}, "")
      end
    end
  end
end
