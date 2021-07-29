module PipelineHelpers
  # this class configures some generation options instead of doing it in pipeline templates
  class PipelineConfigurer
    attr_reader :serial_group_strategy, :parallel_execution_limit, :git_shallow_clone_depth, :concourse_retry

    def initialize(options)
      @options = options
      @parallel_execution_limit = ConfiguredParallelExecutionLimit.new(options.config, options.root_deployment_name)
      @serial_group_strategy = configure_serial_group_strategy
      @git_shallow_clone_depth = ConfiguredGitShallowCloneDepth.new(options.config, options.root_deployment_name)
      @concourse_retry = configure_concourse_retry
    end

    private

    def configure_concourse_retry
      {
        task: ConfiguredRetryTask.new(@options.config, @options.root_deployment_name).get,
        push: ConfiguredRetryPush.new(@options.config, @options.root_deployment_name).get,
        pull: ConfiguredRetryPull.new(@options.config, @options.root_deployment_name).get,
        bosh_push: ConfiguredRetryBoshPush.new(@options.config, @options.root_deployment_name).get
      }
    end

    def configure_serial_group_strategy
      pool_size = @parallel_execution_limit.get
      configured_serial_group_strategy = PipelineHelpers::ConfiguredSerialGroupNamingStrategy.new(@options.config, @options.root_deployment_name)
      configured_serial_group_strategy_class = configured_serial_group_strategy.get
      configured_serial_group_strategy_class.insert(0, 'PipelineHelpers::') unless Object.const_defined?(configured_serial_group_strategy_class)
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
