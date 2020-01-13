module Coa
  module TestFixtures
    require 'yaml'

    RESOURCES = YAML.safe_load <<~YAML
      concourse-meta:
        name: concourse-meta
        icon: file-document-box-search-outline
        type: meta
      failure-alert:
        name: failure-alert
        icon: slack
        type: slack-notification
        source:
          url: ((slack-webhook))
          proxy: ((slack-proxy))
          proxy_https_tunnel: ((slack-proxy-https-tunnel))
          disable: ((slack-disable))
      secrets-DEPLS-for-pipeline:
        name: secrets-<%= depls %>-for-pipeline
        type: git
        source:
          uri: ((secrets-uri))
          branch: ((secrets-branch))
          skip_ssl_verification: true
          paths: [ "<%= depls %>/ci-deployment-overview.yml", coa/config, "coa/pipelines/generated/**/<%= depls %>-*-generated.yml", shared, private-config.yml, "<%= depls %>/**/enable-cf-app.yml", "<%= depls %>/**/enable-deployment.yml" ]
      secrets-writer:
        name: secrets-writer
        icon: source-pull
        type: git
        source:
          uri: ((secrets-uri))
          branch: ((secrets-branch))
          skip_ssl_verification: true
      paas-templates-DEPLS:
        name: paas-templates-<%= depls %>
        icon: home-analytics
        type: git
        source:
          uri: ((paas-templates-uri))
          branch: ((paas-templates-branch))
          skip_ssl_verification: true
          paths: [ "<%= depls %>", '.gitmodules', 'public-config.yml' ]
      cf-ops-automation:
        name: cf-ops-automation
        icon: rocket
        type: git
        source:
          uri: ((cf-ops-automation-uri))
          branch: ((cf-ops-automation-branch))
          tag_filter: ((cf-ops-automation-tag-filter))
          skip_ssl_verification: true
    YAML

    def self.expand_resource_template(key, context)
      yaml_template = RESOURCES[key]&.to_yaml

      expanded_yaml = ERB.new(yaml_template).result(create_custom_binding_from(context))
      YAML.safe_load(expanded_yaml)
    end
  end
end
