require 'find'
require_relative '../../lib/coa/reference_dataset_documentation'

Given("a config repository called {string}") do |string|
  @config_repo_name = string
end

Given("a template repository called {string}") do |string|
  @template_repo_name = string
end

When("I deploy {string}") do |string|
  @root_deployment_name = string
end

When("with the structures shown in {string} in the {string} readme") do |string1, string2|
  @docs_config = Coa::ReferenceDatasetDocumentation::DocsConfig.new(
    root_deployment_name: @root_deployment_name,
    config_repo_name:     @config_repo_name,
    template_repo_name:   @template_repo_name,
    documentation_path:   string1,
    readme_filename:      string2
  )
  @readme = @docs_config.readme
  @readme.rewrite_scructure_documentation
end

Then("the COA creates a set of pipelines") do
  @pipelines = @docs_config.pipelines
  @pipelines.generate
  expect(@pipelines.are_present?).to eq(true)
end

Then("generated pipelines are valid concourse pipelines") do
  @pipelines.validate
  @readme.write_pipeline_documentation
end

But("NYI") do
  pending
end

But("needs documentation") do
  pending
end
