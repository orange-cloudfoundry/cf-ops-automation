module Coa
  module TestFixtures
    RESOURCE_TYPES = YAML.safe_load <<~YAML
      slack-notification:
        name: slack-notification
        type: registry-image
        source:
          repository: elpaasoci/slack-notification-resource
          tag: v1.7.0-orange
      meta:
        name: meta
        type: registry-image
        source:
          repository: elpaasoci/metadata-resource
          tag: 2.0.3-orange


    YAML
  end
end
