require 'rspec'
require_relative 'config_getter_shared_samples'
require_relative '../../../lib/pipeline_helpers'

describe PipelineHelpers::ConfiguredRetryPull do
  it_behaves_like 'a ConfigGetter', Config::CONFIG_PULL_KEY, Config::CONFIG_RETRY_KEY
end

describe PipelineHelpers::ConfiguredRetryPush do
  it_behaves_like 'a ConfigGetter', Config::CONFIG_PUSH_KEY, Config::CONFIG_RETRY_KEY
end

describe PipelineHelpers::ConfiguredRetryBoshPush do
  it_behaves_like 'a ConfigGetter', Config::CONFIG_BOSH_PUSH_KEY, Config::CONFIG_RETRY_KEY
end

describe PipelineHelpers::ConfiguredRetryTask do
  it_behaves_like 'a ConfigGetter', Config::CONFIG_TASK_KEY, Config::CONFIG_RETRY_KEY
end