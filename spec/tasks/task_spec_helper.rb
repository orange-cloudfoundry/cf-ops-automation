class TaskSpecHelper
  def self.reference_dataset_dir
    relative_path = File.join(__FILE__, '..', '..', '..', 'docs', 'reference_dataset')
    File.absolute_path(relative_path)
  end

  def self.bosh_cli_v2_image
    'governmentpaas/bosh-cli-v2'
  end

  def self.bosh_cli_v2_image_version
    'c88f3e0b03558c987693fad3f180d9052b77342c'
  end

  def self.ruby_image
    'ruby'
  end

  def self.ruby_image_version
    '2.3.5-slim'
  end
end
