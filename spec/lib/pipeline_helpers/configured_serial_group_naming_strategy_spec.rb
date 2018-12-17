require 'rspec'
require_relative 'config_getter_shared_samples'
require_relative '../../../lib/pipeline_helpers'

describe PipelineHelpers::ConfiguredSerialGroupNamingStrategy do
  it_behaves_like 'a ConfigGetter', PipelineHelpers::ConfiguredSerialGroupNamingStrategy::CONFIG_SERIAL_GROUP_NAMING_STRATEGY_KEY

end