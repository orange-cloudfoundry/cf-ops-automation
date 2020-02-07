module PipelineHelpers
  # this parent class regroups shared methods to extract configuration information from a +Config+ overview
  class ConfigGetter
    attr_reader :config, :root_deployment_name

    def initialize(config, root_deployment_name = '')
      @config = config
      @root_deployment_name = root_deployment_name
    end

    def get
      extract_from_root_deployment || extract_from_default || default_value
    end

    def default_value
      raise 'Invalid usage, please override'
    end

    def overridden?
      get != default_value
    end

    # should return a value or nil when not found
    def extract(_root_level_name)
      raise 'Invalid usage, please override'
    end

    private

    def extract_from_root_deployment
      extract(@root_deployment_name) unless @root_deployment_name.to_s.empty?
    end

    def extract_from_default
      extract(Config::CONFIG_DEFAULT_KEY)
    end
  end
end
