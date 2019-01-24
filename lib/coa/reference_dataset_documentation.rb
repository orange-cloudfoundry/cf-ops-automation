module Coa
  # This module can generate documentation from a given reference dataset.
  # This includes generating pipelines as well as creating a readme.
  module ReferenceDatasetDocumentation
    require_relative './reference_dataset_documentation/docs_config'
    require_relative './reference_dataset_documentation/file_list_writer'
    require_relative './reference_dataset_documentation/pipelines'
    require_relative './reference_dataset_documentation/pipeline_docs_writer'
    require_relative './reference_dataset_documentation/readme'
    require_relative './reference_dataset_documentation/readme_author'
    require_relative './reference_dataset_documentation/tree_writer'
    require_relative './reference_dataset_documentation/utils_writer'
  end
end
