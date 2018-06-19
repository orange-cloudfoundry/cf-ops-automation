require 'find'
require_relative '../../lib/reference_dataset_documentation'

Given("a config repository called {string}") do |string|
  @config_repo_name = string
end

Given("a template repository called {string}") do |string|
  @template_repo_name = string
end

When("I deploy {string}") do |string|
  @root_deployment_name = string
end

When("I feed the example type called {string}") do |string|
  @example_type = string
end

When("with the structures shown in {string}") do |string|
  @ref = ReferenceDatasetDocumentation::Generator.new(
    root_deployment_name: @root_deployment_name,
    example_type: @example_type,
    config_repo_name: @config_repo_name,
    template_repo_name: @template_repo_name,
    path: string
  )
  @ref.perform
end

Then("the COA should create a set of deployment pipelines") do
  pipelines = @ref.pipelines
  pipelines.generate
  expect(pipelines.are_ok?).to eq(true)
  pipelines.write_pipelines_credential_list
  pipelines.write_credentials_pipeline_list
  pipelines.clean
end
