module Coa
  module ReferenceDatasetDocumentation
    module Helpers
      # This module decentralizes code from the FileListWriter
      module FileListWriterHelpers
        def pretty_filepath(path, repo_name)
          stripped_path = path.strip
          filename = File.basename(stripped_path)
          return "" if filename.empty? || filename[0] == "."
          prefix = extract_prefix(stripped_path)
          cleaned_path = clean_path(stripped_path)
          "#{prefix}* [#{filename}](/docs/reference_dataset/#{repo_name}/#{cleaned_path})"
        end

        def extract_prefix(path)
          path_items = path.strip.gsub(%r{^./}, "").split('/')
          "  " * (path_items.size - 1)
        end

        def clean_path(path)
          path.strip.gsub(%r{^./}, "")
        end
      end
    end
  end
end
