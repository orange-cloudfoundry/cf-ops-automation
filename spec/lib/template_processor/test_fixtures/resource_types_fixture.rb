module Coa
  module TestFixtures
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
          repository: ((docker-registry-url))olhtbr/metadata-resource
          tag: 2.0.1
    YAML
  end
end
