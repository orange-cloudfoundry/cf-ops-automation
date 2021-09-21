require 'rspec'
require_relative 'config_getter_shared_samples'
require_relative '../../../lib/pipeline_helpers'

describe PipelineHelpers::ConfiguredParallelExecutionLimit do
  it_behaves_like 'a ConfigGetter', Config::CONFIG_PARALLEL_EXECUTION_LIMIT_KEY
end
