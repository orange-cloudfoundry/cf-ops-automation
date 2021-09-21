module PipelineHelpers
  # this class looks for ConfiguredReconciliationLoopInterval
  class ConfiguredReconciliationLoopInterval < ConfigGetter
    EACH_FOUR_MINUTES = "4m"
    def default_value
      EACH_FOUR_MINUTES
    end

    def extract(root_level_name)
      config.dig(root_level_name, Config::CONFIG_RECONCILIATION_LOOP_KEY, Config::CONFIG_INTERVAL_KEY)
    end
  end
end
