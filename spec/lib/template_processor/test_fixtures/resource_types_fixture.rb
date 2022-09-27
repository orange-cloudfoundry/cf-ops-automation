module Coa
  module TestFixtures
    RESOURCE_TYPES = YAML.safe_load <<~YAML
      slack-notification:
        name: slack-notification
        type: registry-image
        source:
          repository: cfcommunity/slack-notification-resource
          tag: v1.4.2
      meta:
        name: meta
        type: registry-image
        source:
          repository: olhtbr/metadata-resource
          tag: 2.0.1


    YAML
  end
end
