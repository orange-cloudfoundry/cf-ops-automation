class TaskSpecHelper
  def self.reference_dataset_dir
    relative_path = File.join(__FILE__, '..', '..', '..', 'docs', 'reference_dataset')
    File.absolute_path(relative_path)
  end

  def self.fly_image
    'teliaoss/concourse-fly'
  end

  def self.fly_image_version
    '20210905'
  end

  def self.alpine_image
    'library/alpine'
  end

  def self.alpine_image_version
    '3.13'
  end

  def self.orange_default_image_version
    'e52d0924aa2dc367e078fdb5ff19eecab1b16ed7'
  end

  def self.governmentpaas_default_image_version
    '469ceea7a619b0abdd6cb27efd4d3bd5e9be3ddb'
  end

  def self.spruce_image
    'governmentpaas/spruce'
  end

  def self.spruce_image_version
    governmentpaas_default_image_version
  end

  def self.curl_image
    'governmentpaas/curl-ssl'
  end

  def self.curl_image_version
    governmentpaas_default_image_version
  end

  def self.git_image
    'governmentpaas/git-ssh'
  end

  def self.git_image_version
    governmentpaas_default_image_version
  end

  def self.bosh_cf_cli_image
    'orangecloudfoundry/bosh-cli-v2-cf-cli'
  end

  def self.bosh_cf_cli_image_version
    orange_default_image_version
  end

  def self.bosh_cli_v2_image
    'governmentpaas/bosh-cli-v2'
  end

  def self.bosh_cli_v2_image_version
    governmentpaas_default_image_version
  end

  def self.k8s_tools_image
    'orangecloudfoundry/k8s-tools'
  end

  def self.k8s_tools_image_version
    orange_default_image_version
  end

  def self.cf_cli_image
    'governmentpaas/cf-cli'
  end

  def self.cf_cli_image_version
    governmentpaas_default_image_version
  end

  def self.spruce_image
    'governmentpaas/spruce'
  end

  def self.spruce_image_version
    governmentpaas_default_image_version
  end

  def self.ruby_image
    'library/ruby'
  end

  def self.ruby_image_version
    '2.7.1'
  end

  def self.ruby_slim_image_version
    ruby_image_version + '-slim'
  end

  def self.terraform_image
    'orangecloudfoundry/terraform'
  end

  def self.terraform_image_version
    orange_default_image_version
  end

  def self.pre_deploy_image
    'orangecloudfoundry/bosh-cli-v2-cf-cli'
  end

  def self.pre_deploy_image_version
    orange_default_image_version
  end

  def self.awscli_image
    'governmentpaas/awscli'
  end

  def self.awscli_image_version
    governmentpaas_default_image_version
  end

  def self.load_yaml_fixture(task_name, relative_path_from_fixture_dir)
    base_dir = File.dirname(__FILE__)
    path = File.join(base_dir, task_name, 'fixtures', relative_path_from_fixture_dir)
    raise "File not found: #{path}" unless File.exist?(path)

    YAML.load_file(path)
  end

  def self.resolv_erb_yaml_fixture(task_name, erb_relative_path, context)
    erb_file_full_path = File.join(File.dirname(__FILE__), task_name, 'fixtures', erb_relative_path)
    new_binding = binding
    context&.each do |k, v|
      new_binding.local_variable_set k.to_sym, v
    end
    puts "Local var: #{new_binding.local_variables}"
    YAML.safe_load(ERB.new(File.read(erb_file_full_path), 0, '<>').result(new_binding))
  end
end
