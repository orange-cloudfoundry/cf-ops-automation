class TaskSpecHelper
  def self.reference_dataset_dir
    relative_path = File.join(__FILE__, '..', '..', '..', 'docs', 'reference_dataset')
    File.absolute_path(relative_path)
  end

  def self.alpine_image
    'library/alpine'
  end

  def self.alpine_image_version
    '3.9'
  end

  def self.governmentpaas_default_image_version
    '2857fdbaea59594c06cf9c6e32027091b67d4767'
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

  def self.bosh_cli_v2_image
    'governmentpaas/bosh-cli-v2'
  end

  def self.bosh_cli_v2_image_version
    governmentpaas_default_image_version
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
    '2.6.3'
  end

  def self.ruby_slim_image_version
    ruby_image_version + '-slim'
  end

  def self.terraform_image
    'orangecloudfoundry/terraform'
  end

  def self.terraform_image_version
    '9abcdeea39faad8fd07163c73aa25aa062d174db'
  end
end
