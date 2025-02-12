class TaskSpecHelper
  def self.reference_dataset_dir
    relative_path = File.join(__FILE__, '..', '..', '..', 'docs', 'reference_dataset')
    File.absolute_path(relative_path)
  end

  def self.fly_image
    'elpaasoci/concourse-fly' #from https://github.com/orange-cloudfoundry/concourse-images
  end

  def self.fly_image_version
    '7ce5aa85675911e224c72a3d410fd63d93be1442' # ie '7.9.1'
  end

  def self.orange_default_image_version
    '16d8df77e94455af3bccce2b058318fd3fd8b9bc'
  end

  def self.governmentpaas_default_image_version
    '16d8df77e94455af3bccce2b058318fd3fd8b9bc'
  end

  def self.spruce_image
    'elpaasoci/spruce'
  end

  def self.spruce_image_version
    orange_default_image_version # governmentpaas_default_image_old_version
  end

  def self.curl_image
    'elpaasoci/curl-ssl'
  end

  def self.curl_image_version
    orange_default_image_version # governmentpaas_default_image_old_version
  end

  def self.git_image
    'elpaasoci/git-ssh'
  end

  def self.git_image_version
    orange_default_image_version # governmentpaas_default_image_old_version
  end

  def self.bosh_cf_cli_image
    'elpaasoci/bosh-cli-v2-cf-cli'
  end

  def self.bosh_cf_cli_image_version
    orange_default_image_version
  end

  def self.bosh_cli_v2_image
    'elpaasoci/bosh-cli-v2'
  end

  def self.bosh_cli_v2_image_version
    orange_default_image_version # governmentpaas_default_image_old_version
  end

  def self.k8s_tools_image
    'elpaasoci/k8s-tools'
  end

  def self.k8s_tools_image_version
    orange_default_image_version
  end

  def self.cf_cli_image
    'elpaasoci/bosh-cli-v2-cf-cli'
  end

  def self.cf_cli_image_version
    orange_default_image_version # governmentpaas_default_image_old_version
  end

  def self.spruce_image
    'elpaasoci/spruce'
  end

  def self.spruce_image_version
    orange_default_image_version # governmentpaas_default_image_old_version
  end

  def self.ruby_image
    'library/ruby'
  end

  def self.ruby_image_version
    '3.1.2'
  end

  def self.ruby_slim_image_version
    ruby_image_version + '-slim'
  end

  def self.terraform_image
    'elpaasoci/terraform'
  end

  def self.terraform_image_version
    orange_default_image_version
  end

  def self.pre_deploy_image
    'elpaasoci/bosh-cli-v2-cf-cli'
  end

  def self.pre_deploy_image_version
    orange_default_image_version
  end

  def self.awscli_image
    'elpaasoci/awscli'
  end

  def self.awscli_image_version
    orange_default_image_version # governmentpaas_default_image_old_version
  end

  def self.load_yaml_fixture(task_name, relative_path_from_fixture_dir)
    base_dir = File.dirname(__FILE__)
    path = File.join(base_dir, task_name, 'fixtures', relative_path_from_fixture_dir)
    raise "File not found: #{path}" unless File.exist?(path)

    YAML.load_file(path, aliases: true)
  end

  def self.resolv_erb_yaml_fixture(task_name, erb_relative_path, context)
    erb_file_full_path = File.join(File.dirname(__FILE__), task_name, 'fixtures', erb_relative_path)
    new_binding = binding
    context&.each do |k, v|
      new_binding.local_variable_set k.to_sym, v
    end
    puts "Local var: #{new_binding.local_variables}"
    YAML.safe_load(ERB.new(File.read(erb_file_full_path), trim_mode: '<>').result(new_binding))
  end
end
