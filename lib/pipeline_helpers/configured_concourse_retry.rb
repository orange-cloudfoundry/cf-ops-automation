module PipelineHelpers
  # this class looks for retry config on bosh pull
  class ConfiguredRetryPull < ConfigGetter
    def default_value
      Config::DEFAULT_CONFIG_RETRY_PULL_LIMIT
    end

    def extract(root_level_name)
      config.dig(root_level_name, Config::CONFIG_RETRY_KEY, Config::CONFIG_PULL_KEY)
    end
  end

  # this class looks for retry config on push
  class ConfiguredRetryPush < ConfigGetter
    def default_value
      Config::DEFAULT_CONFIG_RETRY_PUSH_LIMIT
    end

    def extract(root_level_name)
      config.dig(root_level_name, Config::CONFIG_RETRY_KEY, Config::CONFIG_PUSH_KEY)
    end
  end

  # this class looks for retry config on bosh push
  class ConfiguredRetryBoshPush < ConfigGetter
    def default_value
      Config::DEFAULT_CONFIG_RETRY_BOSH_PUSH_LIMIT
    end

    def extract(root_level_name)
      config.dig(root_level_name, Config::CONFIG_RETRY_KEY, Config::CONFIG_BOSH_PUSH_KEY)
    end
  end

  # this class looks for retry config on tasks
  class ConfiguredRetryTask < ConfigGetter
    def default_value
      Config::DEFAULT_CONFIG_RETRY_TASK_LIMIT
    end

    def extract(root_level_name)
      config.dig(root_level_name, Config::CONFIG_RETRY_KEY, Config::CONFIG_TASK_KEY)
    end
  end
end
