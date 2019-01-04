module Coa
  module Utils
    module Bosh
      # This class create an object from a Hash of BOSH credentials
      class Config
        attr_reader :ca_cert, :client, :client_secret, :environment, :target

        def initialize(source)
          @ca_cert       = source["bosh_ca_cert"]
          @client        = source["bosh_client"]
          @client_secret = source["bosh_client_secret"]
          @environment   = source["bosh_environment"]
          @target        = source["bosh_target"]
        end
      end
    end
  end
end
