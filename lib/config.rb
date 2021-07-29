require 'yaml'
require 'fileutils'
require_relative 'active_support_copy_deep_merge'
require_relative 'extended_config'

# Manage configuration shared by root-deployments. A public config file can be overridden by a private config file and
# an extended configuration (based on environment variables)
class Config
  DEFAULT_STEMCELL = 'bosh-openstack-kvm-ubuntu-bionic-go_agent'.freeze
  DEFAULT_PROFILES = [].freeze
  DEFAULT_STEMCELL_PREFIX = 'bosh'.freeze
  EMPTY_BOSH_OPTIONS = {}.freeze
  CONFIG_DEFAULT_KEY = 'default'.freeze
  CONFIG_CONCOURSE_KEY = 'concourse'.freeze
  CONFIG_STEMCELL_KEY = 'stemcell'.freeze
  CONFIG_PARALLEL_EXECUTION_LIMIT_KEY = 'parallel_execution_limit'.freeze
  CONFIG_BOSH_OPTIONS_KEY = 'bosh-options'.freeze
  DEFAULT_CONFIG_PARALLEL_EXECUTION_LIMIT = 5
  CONFIG_GIT_KEY = 'git'.freeze
  CONFIG_SHALLOW_CLONE_DEPTH_KEY = 'shallow-clone-depth'.freeze
  CONFIG_RETRY_KEY = 'retry'.freeze
  CONFIG_PULL_KEY = 'pull'.freeze
  CONFIG_TASK_KEY = 'task'.freeze
  DEFAULT_CONFIG_RETRY_TASK_LIMIT = 2
  DEFAULT_CONFIG_RETRY_PULL_LIMIT = 2
  DEFAULT_CONFIG_RETRY_PUSH_LIMIT = 2
  DEFAULT_CONFIG_RETRY_BOSH_PUSH_LIMIT = DEFAULT_CONFIG_RETRY_PUSH_LIMIT
  CONFIG_PUSH_KEY = 'push'.freeze
  CONFIG_BOSH_PUSH_KEY = 'bosh-push'.freeze
  DEFAULT_RETRY = { CONFIG_TASK_KEY => DEFAULT_CONFIG_RETRY_TASK_LIMIT,CONFIG_PULL_KEY => DEFAULT_CONFIG_RETRY_PULL_LIMIT, CONFIG_PUSH_KEY => DEFAULT_CONFIG_RETRY_PUSH_LIMIT, CONFIG_BOSH_PUSH_KEY => DEFAULT_CONFIG_RETRY_BOSH_PUSH_LIMIT }

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
        },
        CONFIG_RETRY_KEY => DEFAULT_RETRY
      }
    }.deep_merge(@extended_config.default_format)
  end

  def load_config
    public_config = private_config = nil
    public_config = YAML.load_file(@public_yaml) if File.exist?(@public_yaml)
    private_config = YAML.load_file(@private_yaml) if File.exist?(@private_yaml)
    @loaded_config = @loaded_config.deep_merge(public_config) unless public_config.nil?
    @loaded_config = @loaded_config.deep_merge(private_config) unless private_config.nil?
    override_with_extended_config
    puts "Loaded config: #{@loaded_config.to_yaml}"
    self
  end

  def stemcell_name(root_deployment_name = '')
    name = @loaded_config.dig(root_deployment_name, 'stemcell', 'name') || @loaded_config.dig('default', 'stemcell', 'name') || ''
    name.empty? ? DEFAULT_STEMCELL : name
  rescue NoMethodError, TypeError
    DEFAULT_STEMCELL
  end

  def iaas_type(root_deployment_name = '')
    resolve_value(root_deployment_name, 'iaas', '')
  end

  def profiles(root_deployment_name = '')
    resolve_value(root_deployment_name, 'profiles', DEFAULT_PROFILES)
  end

  def bosh_options(root_deployment_name = '')
    resolve_with_deep_merge(root_deployment_name, 'bosh-options', EMPTY_BOSH_OPTIONS)
  rescue NoMethodError, TypeError
    EMPTY_BOSH_OPTIONS
  end

  private

  def override_with_extended_config
    @loaded_config = @loaded_config.deep_merge(@extended_config.default_format)
  end

  def resolve_value(root_deployment_name, key_name, default_value)
    @loaded_config.dig(root_deployment_name, key_name) || @loaded_config.dig('default', key_name) || default_value
  end

  def resolve_with_deep_merge(root_deployment_name, key_name, default_value)
    root_deployment_options = @loaded_config.dig(root_deployment_name, key_name)
    default_options = @loaded_config.dig('default', key_name)
    merged_options = default_value
    merged_options = merged_options.deep_merge(default_options) if default_options
    merged_options = merged_options.deep_merge(root_deployment_options) if root_deployment_options
    merged_options
  end
end
