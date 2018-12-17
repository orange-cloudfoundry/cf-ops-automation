module PipelineHelpers
  # this class looks for ParallelExecutionLimit
  class ConfiguredParallelExecutionLimit < ConfigGetter
    def default_value
      UNLIMITED_EXECUTION
    end

    def extract(root_level_name)
      config.fetch(root_level_name, nil)&.fetch(Config::CONFIG_CONCOURSE_KEY, nil)&.fetch(Config::CONFIG_PARALLEL_EXECUTION_LIMIT_KEY, nil)
    end
  end
end
