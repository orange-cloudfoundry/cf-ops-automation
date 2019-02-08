module Coa
  module Utils
    module Cf
      # This class create an object from a Hash of CF credentials
      class Config
        PUBLIC_PIVOTAL_CLOUDFOUNDRY_URL = "https://api.run.pivotal.io".freeze

        attr_reader :api_url, :username, :password, :org, :space

        def initialize(cf_config = {})
          @api_url     = cf_config["api-url"] || PUBLIC_PIVOTAL_CLOUDFOUNDRY_URL
          @username    = cf_config["username"]
          @password    = cf_config["password"]
          @org         = cf_config["org"]
          @space       = cf_config["space"]
        end

        def to_h
          {
            'cf_api_url' => api_url,
            'cf_username' => username,
            'cf_password' => password,
            'cf_organization' => org,
            'cf_space' => space
          }
        end
      end
    end
  end
end
