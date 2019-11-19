require 'tmpdir'

class TestConfigGenerator
  attr_reader :config_manifest_path

  def initialize
    @config_manifest_path = Dir.mktmpdir
    %w[cloud runtime cpi].each do |type|
      FileUtils.touch(File.join(@config_manifest_path, "my-custom-#{type}-vars.yml"))
      FileUtils.touch(File.join(@config_manifest_path, "01-my-custom-#{type}-operators.yml"))
      FileUtils.touch(File.join(@config_manifest_path, "02-my-custom-#{type}-operators.yml"))
    end
  end

  def cleanup
    FileUtils.rm_rf @config_manifest_path if File.exist?(@config_manifest_path)
  end
end