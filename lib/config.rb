require 'yaml'
require 'fileutils'
require_relative 'active_support_copy_deep_merge'
require_relative 'extended_config'

# Manage configuration shared by root-deployments. A public config file can be overridden by a private config file and
# an extended configuration (based on environment variables)
class Config
  DEFAULT_STEMCELL = 'bosh-openstack-kvm-ubuntu-xenial-go_agent'.freeze
  DEFAULT_PROFILES = [].freeze
  DEFAULT_STEMCELL_PREFIX = 'bosh'.freeze
  CONFIG_DEFAULT_KEY = 'default'.freeze
  CONFIG_CONCOURSE_KEY = 'concourse'.freeze
  CONFIG_STEMCELL_KEY = 'stemcell'.freeze
  CONFIG_PARALLEL_EXECUTION_LIMIT_KEY = 'parallel_execution_limit'.freeze
  CONFIG_BOSH_OPTIONS_KEY = 'bosh-options'.freeze
  DEFAULT_CONFIG_PARALLEL_EXECUTION_LIMIT = 5
  attr_reader :loaded_config

  def initialize(public_yaml_location = '', private_yaml_location = '', extended_config = ExtendedConfigBuilder.new.build)
    @public_yaml = public_yaml_location
    @private_yaml = private_yaml_location
    @extended_config = extended_config
    @loaded_config = default_config
  end

  def default_config
    {
      'offline-mode' => {
        'boshreleases' => false,
        'stemcells' => true,
        'docker-images' => false
      },
      CONFIG_DEFAULT_KEY => {
        CONFIG_STEMCELL_KEY => { 'name' => DEFAULT_STEMCELL },
        CONFIG_CONCOURSE_KEY => { CONFIG_PARALLEL_EXECUTION_LIMIT_KEY => DEFAULT_CONFIG_PARALLEL_EXECUTION_LIMIT },
        CONFIG_BOSH_OPTIONS_KEY => {
          'cleanup' => true, 'no_redact' => false, 'dry_run' => false, 'fix' => false, 'recreate' => false, 'max_in_flight' => nil, 'skip_drain' => []
        }
      }
    }.deep_merge(@extended_config.default_format)
  end

  def load_config
    public_config = private_config = nil
    public_config = YAML.load_file(@public_yaml) if File.exist?(@public_yaml)
    private_config = YAML.load_file(@private_yaml) if File.exist?(@private_yaml)
    @loaded_config = @loaded_config.deep_merge(public_config) unless public_config.nil?
    @loaded_config = @loaded_config.deep_merge(private_config) unless private_config.nil?
    @loaded_config = @loaded_config.deep_merge(@extended_config.default_format)
    puts "Loaded config: #{@loaded_config.to_yaml}"
    self
  end

  def stemcell_name
    name = @loaded_config['default']['stemcell']['name']
    name.empty? ? DEFAULT_STEMCELL : name
  rescue NoMethodError
    DEFAULT_STEMCELL
  end

  def iaas_type
    @loaded_config.dig('default', 'iaas') || ''
  end

  def profiles
    @loaded_config.dig('default', 'profiles') || DEFAULT_PROFILES
  end

  def bosh_options
    @loaded_config.dig('default', 'bosh-options') || {}
  end
end
