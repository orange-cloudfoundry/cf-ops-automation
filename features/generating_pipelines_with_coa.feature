Feature: Deploying pipelines with the COA engine
  As a paas-template user,
  In order to deploy a pipeline with the COA engine
  I want to know the structure of the repos and the file content I need to feed to COA to produce pipelines

  Scenario: Deploying a sample pipeline for BOSH
    As a paas-template-user
    Given a config repository called "config_repository"
    And a template repository called "template_repository"
    When I deploy "bosh-sample"
    And I feed the example type called "hello-world"
    And with the structures shown in "docs/reference_dataset/bosh-sample-hello-world.md"
    Then the COA should create a set of deployment pipelines

  Scenario: Deploying a sample pipeline for cf-apps
    As a paas-template-user
    Given a config repository called "config_repository"
    And a template repository called "template_repository"
    When I deploy "cf-apps-sample"
    And I feed the example type called "hello-world"
    And with the structures shown in "docs/reference_dataset/cf-apps-sample-hello-world.md"
    Then the COA should create a set of deployment pipelines

  Scenario: Deploying a sample pipeline for concourse
    As a paas-template-user
    Given a config repository called "config_repository"
    And a template repository called "template_repository"
    When I deploy "concourse-sample"
    And I feed the example type called "hello-world"
    And with the structures shown in "docs/reference_dataset/concourse-sample-hello-world.md"
    Then the COA should create a set of deployment pipelines

  Scenario: Deploying a sample pipeline for delete-lifecycle
    As a paas-template-user
    Given a config repository called "config_repository"
    And a template repository called "template_repository"
    When I deploy "delete-lifecycle-sample"
    And I feed the example type called "hello-world"
    And with the structures shown in "docs/reference_dataset/delete-lifecycle-sample-hello-world.md"
    Then the COA should create a set of deployment pipelines

  Scenario: Deploying a sample pipeline for terraform
    As a paas-template-user
    Given a config repository called "config_repository"
    And a template repository called "template_repository"
    When I deploy "terraform-sample"
    And I feed the example type called "hello-world"
    And with the structures shown in "docs/reference_dataset/terraform-sample-hello-world.md"
    Then the COA should create a set of deployment pipelines
