require 'rspec'
require_relative 'config_getter_shared_samples'
require_relative '../../../lib/pipeline_helpers'

describe PipelineHelpers::ConfiguredReconciliationLoopInterval do
  it_behaves_like 'a ConfigGetter', Config::CONFIG_INTERVAL_KEY, Config::CONFIG_RECONCILIATION_LOOP_KEY
end
