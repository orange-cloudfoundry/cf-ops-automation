require_relative 'reference_dataset_documentation/file_list_writer'
require_relative 'reference_dataset_documentation/tree_writer'
require_relative 'reference_dataset_documentation/pipelines'
require_relative 'reference_dataset_documentation/generator'

# This modules can generates documents in which are displayed a config repo tree
# and a template repo tree as well as links to the files displayed for a
# given root deployment (bosh, concourse, etc.) in combination with an example
# type (hello-world). This generation happens from the reference dataset
# in the "docs" directory and also lands there.
module ReferenceDatasetDocumentation
  PROJECT_ROOT_DIR = Pathname.new(__FILE__).join("../../..")
end
