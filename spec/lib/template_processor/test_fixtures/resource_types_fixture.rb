module Coa
  module TestFixtures
    require 'yaml'

    RESOURCE_TYPES = YAML.safe_load <<~YAML
      slack-notification:
        name: slack-notification
        type: docker-image
        source:
          repository: ((docker-registry-url))cfcommunity/slack-notification-resource
          tag: v1.4.2
      meta:
        name: meta
        type: docker-image
        source:
          repository: ((docker-registry-url))swce/metadata-resource
          tag: release-v0.0.3
    YAML
  end
end
