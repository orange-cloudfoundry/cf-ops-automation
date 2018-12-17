module PipelineHelpers
  # this class defines a basic round robin strategy
  class SerialGroupRoundRobinNamingStrategy < SerialGroupNamingStrategy
    def initialize(max_pool_size = DEFAULT_MAX_POOL_SIZE, name_prefix = DEFAULT_PREFIX)
      super(max_pool_size, name_prefix)
      @concurrent_group_counter = -1
    end

    def generate(_name, _details)
      @concurrent_group_counter += 1
      prefix + (@concurrent_group_counter % max_pool_size).to_s
    end

    def reset
      @concurrent_group_counter = -1
    end
  end
end
