require 'yaml'
require 'fileutils'

class Config
  def initialize(public_yaml_location, private_yaml_location)
    @public_yaml = public_yaml_location
    @private_yaml = private_yaml_location
    @loaded_config = default_config
  end

  def default_config
    {
      'offline-mode' => {
         'boshreleases' => false,
         'stemcells' => true ,
         'docker-images' => false }
    }
  end

  def load
    public_config = YAML.load_file(@public_yaml) if File.exist?(@public_yaml)
    private_config = YAML.load_file(@private_yaml) if File.exist?(@private_yaml)
    @loaded_config.merge!(public_config) unless public_config.nil?
    @loaded_config.merge!(private_config) unless private_config.nil?
    @loaded_config
  end
end