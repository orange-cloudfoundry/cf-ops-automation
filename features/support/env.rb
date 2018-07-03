require_relative '../../lib/reference_dataset_documentation'

puts '_____________________'
puts 'Before running COA tests, we remove all generated pipelines from output_dir'
puts '_____________________'
ReferenceDatasetDocumentation::Pipelines.cleanup_generation_dir
