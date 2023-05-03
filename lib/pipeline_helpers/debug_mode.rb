module PipelineHelpers
  # This class manage COA debug mode flag
  class DebugMode < ConfigGetter
    NO_DEBUG = false
    def default_value
      NO_DEBUG
    end

    def extract(root_level_name)
      # config.dig(root_level_name, Config::CONFIG_DEBUG_MODE)
      config.fetch(root_level_name, nil)&.fetch(Config::CONFIG_DEBUG_MODE, nil)
    end
  end
end
