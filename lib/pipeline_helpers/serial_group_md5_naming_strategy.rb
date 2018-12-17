module PipelineHelpers
  # this class defines a strategy based on md5 encoded name, used as random seed
  class SerialGroupMd5NamingStrategy < SerialGroupNamingStrategy
    require 'digest'

    HEXADECIMAL_BASE = 16

    def generate(name, _details)
      md5_encoded_name = Digest::MD5.hexdigest(name)
      seed = Integer(md5_encoded_name, HEXADECIMAL_BASE)
      Random.srand(seed)
      prefix + rand(max_pool_size).to_s
    end
  end
end
