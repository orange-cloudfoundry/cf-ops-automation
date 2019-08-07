class TaskSpecHelper
  def self.reference_dataset_dir
    relative_path = File.join(__FILE__, '..', '..', '..', 'docs', 'reference_dataset')
    File.absolute_path(relative_path)
  end

  def self.governmentpaas_default_image_version
    '7a7678281e1f152183c7359546912df68f298664'
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
    '8fa84b3fe7e7789769dd103f3d6abfef09a771fd'
  end
end
