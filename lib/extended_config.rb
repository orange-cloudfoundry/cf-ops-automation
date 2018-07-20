require 'yaml'
require 'fileutils'

# Hold configuration retrieved from environment variable
class ExtendedConfig
  IAAS_TYPE_KEY = 'IAAS_TYPE'.freeze
  DEFAULT_IAAS_TYPE = 'openstack'.freeze

  attr_reader :extended_config

  def default_config
    {
      'default' => {
        'iaas' => default_iaas_type
      }
    }
  end

  def initialize(env = {})
    @extended_config = env
  end

  def ==(other)
    return false unless other.is_a?(ExtendedConfig)
    @extended_config == other.extended_config
  end

  private

  def default_iaas_type
    @extended_config.fetch(IAAS_TYPE_KEY, DEFAULT_IAAS_TYPE)
  end
end

# Ease creation of ExtendedConfig
class ExtendedConfigBuilder
  def initialize
    @current_config = {}
  end

  def build
    ExtendedConfig.new(@current_config)
  end

  def with_iaas_type(name)
    @current_config[ExtendedConfig::IAAS_TYPE_KEY] = name
    self
  end
end
