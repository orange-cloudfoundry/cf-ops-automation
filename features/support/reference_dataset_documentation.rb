require_relative 'reference_dataset_documentation/file_list_writer'
require_relative 'reference_dataset_documentation/tree_writer'
require_relative 'reference_dataset_documentation/pipelines'
require_relative 'reference_dataset_documentation/generator'

module ReferenceDatasetDocumentation
  PROJECT_ROOT_DIR = Pathname.new(__FILE__).join("../../..")
end
