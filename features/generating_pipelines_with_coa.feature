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
    And with the structures shown in "docs/reference_dataset/hello-world-root-depls.md"
    Then the COA creates a set of deployment pipelines
    And generated pipelines are valid concourse pipelines

  Scenario: Creating a set of empty pipelines for 'another world' root deployment
    As a paas-template-user
    When I deploy "another-world-root-depls"
    And with the structures shown in "docs/reference_dataset/another-world-root-depls.md"
    Then the COA creates a set of deployment pipelines
    And generated pipelines are valid concourse pipelines
