require_relative '../../lib/coa/reference_dataset_documentation'
require_relative '../../lib/coa/constants'

puts '_____________________'
puts 'Before running COA tests, we remove all generated pipelines from output_dir'
puts '_____________________'

Coa::ReferenceDatasetDocumentation::DocsConfig.
  cleanup_generated_pipelines(File.join(Coa::Constants::REFERENCE_DATASET_PATH, 'docs/reference_dataset'))
