require 'rspec'
require_relative 'config_getter_shared_samples'
require_relative '../../../lib/pipeline_helpers'

describe PipelineHelpers::DebugMode do
  NO_INTERMEDIATE_KEY = "".freeze

  it_behaves_like 'a ConfigGetter', Config::CONFIG_DEBUG_MODE, NO_INTERMEDIATE_KEY
end
