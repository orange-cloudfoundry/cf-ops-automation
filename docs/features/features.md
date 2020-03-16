Feature: Cf application deployment support
  In order to know how to deploy a CF application
  As a paas-template user,
  I want to know which environment varaiables are availlable

  Background: 
    Given Hello world generated pipelines from reference_dataset

  Scenario: a deployment, or a part, is done using a concourse pipeline
    But needs documentation

Feature: Creating pipelines with the COA engine
  As a paas-template user,
  In order to deploy a pipeline with the COA engine
  I want to know the structure of the repos and the file content I need to feed to COA to produce pipelines

  Background: 
    Given a config repository called "config_repository"
    And a template repository called "template_repository"

  Scenario: Creating sample pipelines for 'Hello World' root deployment
    As a paas-template-user
    When I deploy "hello-world-root-depls"
    And with the structures shown in "docs/reference_dataset" in the "hello-world-root-depls.md" readme
    Then the COA creates a set of pipelines
    And generated pipelines are valid concourse pipelines

  Scenario: Creating a set of empty pipelines for 'another world' root deployment
    As a paas-template-user
    When I deploy "another-world-root-depls"
    And with the structures shown in "docs/reference_dataset" in the "another-world-root-depls.md" readme
    Then the COA creates a set of pipelines
    And generated pipelines are valid concourse pipelines

Feature: Iaas specific support
  In order to support iaas specific features
  As a paas-template user,
  I want to know mechanisms provided by COA

  Background: 
    Given Hello world generated pipelines from reference_dataset

  Scenario: Terraform iaas specific
    But needs documentation

  Scenario: Bosh iaas specific
    But needs documentation

Feature: Multi deployer support
  In order to create a deployment targeting multiple deployer (ie: bosh, terraform, concourse-pipeline, etc...)
  As a paas-template user,
  I want to know mechanisms provided by COA

  Background: 
    Given Hello world generated pipelines from reference_dataset

  Scenario: a deployment, or a part,  is done using Bosh
    But needs documentation

  Scenario: a deployment, or a part, is done using Terraform
    But NYI

  Scenario: a deployment, or a part, is done using a concourse pipeline
    But needs documentation

Feature: Offline support
  In order to support internet lost
  As a paas-template user,
  I want to know mechanisms provided by COA

  Background: 
    Given Hello world generated pipelines from reference_dataset

  Scenario: Bosh release offline
    But needs documentation

  Scenario: Private Docker registry
    But NYI

  Scenario: Bosh stemcells are retrieved from S3
    But needs documentation

Feature: Terraform support for root deployment
  In order to share a terraform across a root deployment
  As a paas-template user,
  I want to know mechanisms provided by COA

  Background: 
    Given Hello world generated pipelines from reference_dataset

  Scenario: a deployment, or a part, is done using a concourse pipeline
    But needs documentation

12 scenarios (10 undefined, 2 passed)
32 steps (10 skipped, 10 undefined, 12 passed)
0m2.060s

You can implement step definitions for undefined steps with these snippets:

Given("Hello world generated pipelines from reference_dataset") do
  pending # Write code here that turns the phrase above into concrete actions
end

