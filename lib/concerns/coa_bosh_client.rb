require_relative './coa_command_runner'

# This class serves as an interface to BOSH, mainly using its CLI.
class CoaBoshClient
  attr_reader :config

  def initialize(config)
    @config = config
  end

  def update_cloud_config(cloud_config_path)
    run_cmd "bosh -n update-cloud-config #{cloud_config_path}"
  end

  def upload_stemcell(uri, sha)
    run_cmd "bosh -n upload-stemcell --sha1 #{sha} #{uri}"
  end

  def deployment_first_vm_ip(deployment_name)
    run_cmd("bosh -d #{deployment_name} is --column ips|cut -f1").chomp
  end

  def upload_release(path, sha)
    run_cmd "bosh upload-release --sha1 #{sha} #{path}"
  end

  def deploy(deployment_name, manifest_path)
    run_cmd "bosh -n deploy -d #{deployment_name} #{manifest_path}"
  end

  def stemcell_uploaded?(name, version)
    entity_uploaded?("stemcells", name, version)
  end

  def release_uploaded?(name, version)
    entity_uploaded?("releases", name, version)
  end

  def run_cmd(cmd)
    CoaCommandRunner.new(cmd, profile: source_profile).execute
  end

  private

  def source_profile
    config.
      map { |key, value| "export BOSH_#{key.tr('-', '_').upcase}='#{value}'" }.
      join("\n")
  end

  def entity_uploaded?(entity_name, name, version)
    run_cmd("bosh #{entity_name} --column name --column version | cut -f1,2").
      split("\n").map(&:split).
      keep_if do |entity|
      entity[0] == name && entity[1].match(/#{version}\*{0,1}/)
    end.first
  end
end
