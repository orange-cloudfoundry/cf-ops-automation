require_relative '../../lib/coa/reference_dataset_documentation'
require_relative '../../lib/coa/constants'

puts '_____________________'
puts 'Before running COA tests, we remove all generated pipelines from output_dir'
puts "Reminder: \e[31mLogs are available at './coa_run_stdout.log'\e[0m"
puts '_____________________'

Coa::ReferenceDatasetDocumentation::DocsConfig.
  cleanup_generated_pipelines(Coa::Constants::REFERENCE_DATASET_PATH)
