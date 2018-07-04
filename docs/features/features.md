Feature: Cf application deployment support
  In order to know how to deploy a CF application
  As a paas-template user,
  I want to know which environment varaiables are availlable

  Background: 
    Given Hello world generated pipelines from reference_dataset

  Scenario: a deployment, or a part, is done using a concourse pipeline
    But needs documentation
      TODO (Cucumber::Pending)
      ./features/step_definitions/pipeline_generation.rb:55:in `"needs documentation"'
      features/cf_app_deployment_environment_variable_available.feature:10:in `But needs documentation'
    Then the following environment variables exist:
      | name              | description                                                                     |
      | GENERATE_DIR      | directory holding generated files. It's an absolute path.                       |
      | BASE_TEMPLATE_DIR | directory where `pre-cf-push.sh` is located. It's an relative path.             |
      | SECRETS_DIR       | directory holding secrets related to current deployment. It's an relative path. |
      | CF_API_URL        | current application Cloud Foundry API url                                       |
      | CF_USERNAME       | current Cloud Foundry application user                                          |
      | CF_PASSWORD       | current Cloud Foundry application user password                                 |
      | CF_ORG            | current Cloud Foundry application organization                                  |
      | CF_SPACE          | current Cloud Foundry application space                                         |
      | CUSTOM_SCRIPT_DIR | TODO                                                                            |
      | CF_MANIFEST       | TODO                                                                            |

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

Feature: Iaas specific support
  In order to support iaas specific features
  As a paas-template user,
  I want to know mechanisms provided by COA

  Background: 
    Given Hello world generated pipelines from reference_dataset

  Scenario: Terraform iaas specific
    But needs documentation
      TODO (Cucumber::Pending)
      ./features/step_definitions/pipeline_generation.rb:55:in `"needs documentation"'
      features/iaas_specific_support.feature:10:in `But needs documentation'

  Scenario: Bosh iaas specific
    But needs documentation
      TODO (Cucumber::Pending)
      ./features/step_definitions/pipeline_generation.rb:55:in `"needs documentation"'
      features/iaas_specific_support.feature:13:in `But needs documentation'

Feature: Multi deployer support
  In order to create a deployment targeting multiple deployer (ie: bosh, terraform, concourse-pipeline, etc...)
  As a paas-template user,
  I want to know mechanisms provided by COA

  Background: 
    Given Hello world generated pipelines from reference_dataset

  Scenario: a deployment, or a part,  is done using Bosh
    But needs documentation
      TODO (Cucumber::Pending)
      ./features/step_definitions/pipeline_generation.rb:55:in `"needs documentation"'
      features/multi_deployer_support.feature:10:in `But needs documentation'

  Scenario: a deployment, or a part, is done using Terraform
    But NYI
      TODO (Cucumber::Pending)
      ./features/step_definitions/pipeline_generation.rb:51:in `"NYI"'
      features/multi_deployer_support.feature:13:in `But NYI'

  Scenario: a deployment, or a part, is done using a concourse pipeline
    But needs documentation
      TODO (Cucumber::Pending)
      ./features/step_definitions/pipeline_generation.rb:55:in `"needs documentation"'
      features/multi_deployer_support.feature:16:in `But needs documentation'

Feature: Offline support
  In order to support internet lost
  As a paas-template user,
  I want to know mechanisms provided by COA

  Background: 
    Given Hello world generated pipelines from reference_dataset

  Scenario: Bosh release offline
    But needs documentation
      TODO (Cucumber::Pending)
      ./features/step_definitions/pipeline_generation.rb:55:in `"needs documentation"'
      features/offline_support.feature:10:in `But needs documentation'

  Scenario: Private Docker registry
    But NYI
      TODO (Cucumber::Pending)
      ./features/step_definitions/pipeline_generation.rb:51:in `"NYI"'
      features/offline_support.feature:13:in `But NYI'

  Scenario: Bosh stemcells are retrieved from S3
    But needs documentation
      TODO (Cucumber::Pending)
      ./features/step_definitions/pipeline_generation.rb:55:in `"needs documentation"'
      features/offline_support.feature:16:in `But needs documentation'

Feature: Terraform support for root deployment
  In order to share a terraform across a root deployment
  As a paas-template user,
  I want to know mechanisms provided by COA

  Background: 
    Given Hello world generated pipelines from reference_dataset

  Scenario: a deployment, or a part, is done using a concourse pipeline
    But needs documentation
      TODO (Cucumber::Pending)
      ./features/step_definitions/pipeline_generation.rb:55:in `"needs documentation"'
      features/terraform_support_for_root_deployment.feature:10:in `But needs documentation'

12 scenarios (10 pending, 2 passed)
33 steps (1 undefined, 10 pending, 22 passed)
0m6.896s

You can implement step definitions for undefined steps with these snippets:

Then("the following environment variables exist:") do |table|
  # table is a Cucumber::MultilineArgument::DataTable
  pending # Write code here that turns the phrase above into concrete actions
end

