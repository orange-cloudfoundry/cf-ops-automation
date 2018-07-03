require 'find'
require_relative '../../lib/reference_dataset_documentation'

Given("a config repository called {string}") do |string|
  @config_repo_name = string
end

Given("a template repository called {string}") do |string|
  @template_repo_name = string
end

Given("Hello world generated pipelines from reference_dataset") do
  @ref = ReferenceDatasetDocumentation::Generator.new(
    root_deployment_name: 'hello-world-root-depls',
    config_repo_name: 'config_repository',
    template_repo_name: 'template_repository',
    path: Dir.mktmpdir
  )
  pipelines = @ref.pipelines
  pipelines.generate
end

When("I deploy {string}") do |string|
  @root_deployment_name = string
end

When("with the structures shown in {string}") do |string|
  @ref = ReferenceDatasetDocumentation::Generator.new(
    root_deployment_name: @root_deployment_name,
    config_repo_name: @config_repo_name,
    template_repo_name: @template_repo_name,
    path: string
  )
  @ref.perform
end

Then("the COA creates a set of deployment pipelines") do
  pipelines = @ref.pipelines
  pipelines.generate
  expect(pipelines.are_present?).to eq(true)
  pipelines.write_pipelines_credential_list
  pipelines.write_credentials_pipeline_list
end

Then("generated pipelines are valid concourse pipelines") do
  pipelines = @ref.pipelines
  pipelines.validate
end

But("NYI") do
  pending
end

But("needs documentation") do
  pending
end
