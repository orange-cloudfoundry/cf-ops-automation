class TaskSpecHelper
  def self.reference_dataset_dir
    relative_path = File.join(__FILE__, '..', '..', '..', 'docs', 'reference_dataset')
    File.absolute_path(relative_path)
  end

  def self.governmentpaas_default_image_version
    'b3185eed905c8320013c5d09b6b18cdc0b68ce36'
  end

  def self.bosh_cli_v2_image
    'governmentpaas/bosh-cli-v2'
  end

  def self.bosh_cli_v2_image_version
    self.governmentpaas_default_image_version
  end

  def self.cf_cli_image
    'governmentpaas/cf-cli'
  end

  def self.cf_cli_image_version
    self.governmentpaas_default_image_version
  end

  def self.spruce_image
    'governmentpaas/spruce'
  end

  def self.spruce_image_version
    self.governmentpaas_default_image_version
  end

  def self.ruby_image
    'ruby'
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
