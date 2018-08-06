module PipelineHelpers
  class << self
    def bosh_io_hosted?(info)
      info["base_location"]&.include?("bosh.io")
    end
  end
end
