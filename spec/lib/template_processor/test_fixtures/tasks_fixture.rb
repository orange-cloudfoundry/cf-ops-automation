module Coa
  module TestFixtures
    TASK_PARAMS = YAML.safe_load <<~YAML
      fly-into-concourse:
          ATC_EXTERNAL_URL: ((concourse-<%= depls %>-target))
          FLY_USERNAME: ((concourse-<%= depls %>-username))
          FLY_PASSWORD: ((concourse-<%= depls %>-password))
          FLY_TEAM: <%= team || 'main' %>
    YAML

    def self.expand_task_params_template(key, context)
      yaml_template = TASK_PARAMS[key]&.to_yaml

      expanded_yaml = ERB.new(yaml_template).result(create_custom_binding_from(context))
      YAML.safe_load(expanded_yaml)
    end
  end
end
