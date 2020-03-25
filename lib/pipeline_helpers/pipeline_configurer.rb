module PipelineHelpers
  # this class configures some generation options instead of doing it in pipeline templates
  class PipelineConfigurer
    attr_reader :serial_group_strategy, :parallel_execution_limit, :git_shallow_clone_depth

    def initialize(options)
      @options = options
      @parallel_execution_limit = ConfiguredParallelExecutionLimit.new(options.config, options.root_deployment_name)
      @serial_group_strategy = configure_serial_group_strategy
      @git_shallow_clone_depth = ConfiguredGitShallowCloneDepth.new(options.config, options.root_deployment_name)
    end

    private

    def configure_serial_group_strategy
      pool_size = @parallel_execution_limit.get
      configured_serial_group_strategy = ConfiguredSerialGroupNamingStrategy.new(@options.config, @options.root_deployment_name)
      configured_serial_group_strategy_class = 'PipelineHelpers::' + configured_serial_group_strategy.get
      Object.const_get(configured_serial_group_strategy_class).new(pool_size)
    end
  end

  # this class formats parameters to be used by +PipelineConfigurer+
  class PipelineConfigurerOptions
    def with_config(config_map)
      @config = config_map
      self
    end

    def with_root_deployment(name)
      @root_deployment_name = name
      self
    end

    def build
      raise MissingPipelineConfigurerOptions, 'Missing config' unless @config

      raise MissingPipelineConfigurerOptions, 'Missing root_deployment_name' unless @root_deployment_name

      OpenStruct.new(config: @config, root_deployment_name: @root_deployment_name)
    end
  end

  # class to handle error raised when a missing required parameter is detected
  class MissingPipelineConfigurerOptions < RuntimeError; end
end
