require 'yaml'
require 'fileutils'
require_relative 'active_support_copy_deep_merge'
require_relative 'extended_config'

class Config
  DEFAULT_STEMCELL = 'bosh-openstack-kvm-ubuntu-trusty-go_agent'.freeze

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
      'default' => {
        'stemcell' => { 'name' => DEFAULT_STEMCELL }
      }
    }.deep_merge(@extended_config.default_config)
  end

  def load_config
    public_config = YAML.load_file(@public_yaml) if File.exist?(@public_yaml)
    private_config = YAML.load_file(@private_yaml) if File.exist?(@private_yaml)
    @loaded_config = @loaded_config.deep_merge(public_config) unless public_config.nil?
    @loaded_config = @loaded_config.deep_merge(private_config) unless private_config.nil?
    @loaded_config = @loaded_config.deep_merge(@extended_config.default_config)
    self
  end

  def stemcell_name
    name = @loaded_config['default']['stemcell']['name']
    name.empty? ? DEFAULT_STEMCELL : name
  rescue NoMethodError
    DEFAULT_STEMCELL
  end

  def iaas_type
    @loaded_config['default']['iaas']
  end
end
