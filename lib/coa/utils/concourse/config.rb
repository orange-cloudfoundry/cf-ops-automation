module Coa
  module Utils
    module Concourse
      # This class create an object from a Hash of Concourse credentials.
      class Config
        CONCOURSE_TARGET = "concourse-target".freeze

        attr_reader :target, :url, :username, :password, :insecure, :ca_cert

        def initialize(source)
          insecure = source["concourse_insecure"].to_s
          insecure = "true" if insecure.empty?

          @target   = source["concourse_target"] || CONCOURSE_TARGET
          @url      = source["concourse_url"]
          @username = source["concourse_username"]
          @password = source["concourse_password"]
          @insecure = insecure
          @ca_cert  = source["concourse_ca_cert"]
        end

        # @insecure is stored as a string because of the way Concourse used to
        # work.
        def insecure?
          insecure == "true"
        end
      end
    end
  end
end
