require 'yaml'
require 'fileutils'

class Config
  DEFAULT_STEMCELL = 'bosh-openstack-kvm-ubuntu-trusty-go_agent'.freeze

  def initialize(public_yaml_location = '', private_yaml_location = '')
    @public_yaml = public_yaml_location
    @private_yaml = private_yaml_location
    @loaded_config = default_config
  end

  def default_config
    {
      'offline-mode' => { 'boshreleases' => false, 'stemcells' => true, 'docker-images' => false },
      'default' => {
        'stemcell' => { 'name' => DEFAULT_STEMCELL }
      }
    }
  end

  def load
    public_config = YAML.load_file(@public_yaml) if File.exist?(@public_yaml)
    private_config = YAML.load_file(@private_yaml) if File.exist?(@private_yaml)
    @loaded_config.merge!(public_config) unless public_config.nil?
    @loaded_config.merge!(private_config) unless private_config.nil?
    @loaded_config
  end

  def stemcell_name
    return DEFAULT_STEMCELL if nil_or_empty?(@loaded_config) || nil_or_empty?(@loaded_config['default']) || nil_or_empty?(@loaded_config['default']['stemcell']) || nil_or_empty?(@loaded_config['default']['stemcell']['name'])
    @loaded_config['default']['stemcell']['name']
  end

  private

  def nil_or_empty?(value)
    value.to_s.empty?
  end
end
