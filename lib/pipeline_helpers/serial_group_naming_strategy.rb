module PipelineHelpers
  # this parent class defines methods required to implement a serial group naming strategy
  class SerialGroupNamingStrategy
    attr_reader :max_pool_size, :prefix
    DEFAULT_PREFIX = 'concurrent-group-'.freeze
    DEFAULT_MAX_POOL_SIZE = Config::DEFAULT_CONFIG_PARALLEL_EXECUTION_LIMIT

    def initialize(max_pool_size = DEFAULT_MAX_POOL_SIZE, name_prefix = DEFAULT_PREFIX)
      @max_pool_size = max_pool_size
      @prefix = name_prefix
    end

    def generate(_name, _details); end

    def reset; end
  end
end
