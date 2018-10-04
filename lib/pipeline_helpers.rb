module PipelineHelpers
  TERRAFORM_CONFIG_DIRNAME_KEY = 'terraform_config'.freeze

  class << self
    def bosh_io_hosted?(info)
      info["base_location"]&.include?("bosh.io")
    end
  end
end
