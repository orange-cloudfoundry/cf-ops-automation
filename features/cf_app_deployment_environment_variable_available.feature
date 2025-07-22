Feature: Cf application deployment support
  In order to know how to deploy a CF application
  As a paas-template user,
  I want to know which environment variables are available

  Background:
    Given Hello world generated pipelines from reference_dataset

  Scenario: a deployment, or a part, is done using a concourse pipeline
    But needs documentation
#    Then the following environment variables exist:
#      | name              | description                                                                     |
#      | GENERATE_DIR      | directory holding generated files. It's an absolute path.                       |
#      | BASE_TEMPLATE_DIR | directory where `pre-cf-push.sh` is located. It's an relative path.             |
#      | SECRETS_DIR       | directory holding secrets related to current deployment. It's an relative path. |
#      | CF_API_URL        | current application Cloud Foundry API url                                       |
#      | CF_USERNAME       | current Cloud Foundry application user                                          |
#      | CF_PASSWORD       | current Cloud Foundry application user password                                 |
#      | CF_ORG            | current Cloud Foundry application organization                                  |
#      | CF_SPACE          | current Cloud Foundry application space                                         |
#      | CUSTOM_SCRIPT_DIR | TODO                                         |
#      | CF_MANIFEST       | TODO                                         |
#
