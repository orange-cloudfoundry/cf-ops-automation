module PipelineHelpers
  # this class looks for ParallelExecutionLimit
  class ConfiguredGitShallowCloneDepth < ConfigGetter
    NO_SHALLOW_CLONE = 0
    def default_value
      NO_SHALLOW_CLONE
    end

    def extract(root_level_name)
      config.dig(root_level_name, Config::CONFIG_GIT_KEY, Config::CONFIG_SHALLOW_CLONE_DEPTH_KEY)
    end
  end
end
