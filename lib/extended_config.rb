require 'yaml'
require 'fileutils'

# Hold configuration retrieved from environment variable, but it does not directly interact with environment variables
class ExtendedConfig
  IAAS_TYPE_ENV_KEY = 'IAAS_TYPE'.freeze
  PROFILES_ENV_KEY = 'PROFILES'.freeze
  ENV_DEFAULT_IAAS_TYPE = 'openstack'.freeze
  PROFILES_KEY = 'profiles'.freeze
  ENV_DEFAULT_PROFILES = [].freeze
  DEFAULT_KEY = 'default'.freeze
  DEFAULT_IAAS_KEY = 'iaas'.freeze

  attr_reader :extended_config

  # @deprecated, please use .default_format
  def default_config
    default_format
  end

  def default_format
    {
      DEFAULT_KEY => {
        DEFAULT_IAAS_KEY => iaas_type,
        PROFILES_KEY => profiles
      }
    }
  end

  def initialize(minimal_env_vars = {})
    @extended_config = minimal_env_vars
  end

  def ==(other)
    return false unless other.is_a?(ExtendedConfig)

    @extended_config == other.extended_config
  end

  def to_s
    @extended_config.to_s
  end

  private

  def iaas_type
    @extended_config.fetch(IAAS_TYPE_ENV_KEY, ENV_DEFAULT_IAAS_TYPE)
  end

  def profiles
    @extended_config.fetch(PROFILES_ENV_KEY, ENV_DEFAULT_PROFILES)
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

  def with_profiles(profiles)
    @current_config[ExtendedConfig::PROFILES_ENV_KEY] = profiles if profiles
    self
  end

  def with_iaas_type(name)
    @current_config[ExtendedConfig::IAAS_TYPE_ENV_KEY] = name if name
    self
  end
end
