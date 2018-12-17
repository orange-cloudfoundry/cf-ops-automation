module PipelineHelpers
  # this class looks for SerialGroupNamingStrategy
  class ConfiguredSerialGroupNamingStrategy < ConfigGetter
    CONFIG_SERIAL_GROUP_NAMING_STRATEGY_KEY = 'serial_group_naming_strategy'.freeze

    def default_value
      SerialGroupRoundRobinNamingStrategy.name
    end

    def extract(root_level_name)
      config.fetch(root_level_name, nil)&.fetch(Config::CONFIG_CONCOURSE_KEY, nil)&.fetch(CONFIG_SERIAL_GROUP_NAMING_STRATEGY_KEY, nil)
    end
  end
end
