module Coa
  module TestFixtures
    require 'yaml'
    require_relative 'test_fixtures/jobs_fixture'
    require_relative 'test_fixtures/resource_fixture'
    require_relative 'test_fixtures/resource_types_fixture'
    require_relative 'test_fixtures/tasks_fixture'

    def self.create_custom_binding_from(context)
      custom_binding = binding
      context&.each { |k, v| custom_binding.local_variable_set k.to_sym, v }
      custom_binding
    end
  end
end