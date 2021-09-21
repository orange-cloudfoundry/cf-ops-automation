require 'rspec'
require_relative 'config_getter_shared_samples'
require_relative '../../../lib/pipeline_helpers'

describe PipelineHelpers::ConfiguredGitShallowCloneDepth do
  it_behaves_like 'a ConfigGetter', Config::CONFIG_SHALLOW_CLONE_DEPTH_KEY, Config::CONFIG_GIT_KEY
end
