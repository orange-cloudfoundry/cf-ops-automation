# Change Log

## [v1.9.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.9.1) (2018-05-29)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.9.0...v1.9.1)

**Fixed bugs:**

- Errands are not always trigger after deployment [\#137](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/137)
- Move out stemcell declararation from deployment-dependencies.yml [\#129](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/129)
- cf app pipeline triggers concurrent updates instead of serializing them [\#123](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/123)

**Closed issues:**

- Test ticket from Code Climate [\#132](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/132)
- Remove custom slack certificates - requires concourse 3.9.1 [\#105](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/105)
- Support Iaas specific TF configs loading [\#38](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/38)

**Merged pull requests:**

- task\(terraform\_\*\):fix helm terraform provider [\#140](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/140)
- pipeline\(depls\): fixes errand job triggering [\#138](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/138)
- Move out stemcell declararation from deployment-dependencies.yml [\#136](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/136)
- task\(terraform\_\*\): bump providers \(openstack, grafana, credhub and helm\) [\#134](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/134)
- Update terraform dev env to enable use of docker images used by COA [\#133](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/133)
- Reference Dataset [\#131](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/131)
- add value 'serial: true' to cf-push-app job in cf-apps-pipeline [\#127](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/127)
- tasks\(terraform\_\*\): add iaas\_type support [\#126](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/126)
- pipeline\(\*\): reduce retry number [\#118](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/118)
- Suggestions for slight Changes [\#116](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/116)
- feature: multi deployer support [\#115](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/115)
- pipeline\(sync-\*-branches, bootstrap-all-init\): updates [\#114](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/114)

## [v1.9.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.9.0) (2018-02-27)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.7.3...v1.9.0)

## [v1.7.3](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.7.3) (2018-02-22)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.8.4...v1.7.3)

**Closed issues:**

- S3 upload pipeline should handle additional teams [\#100](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/100)
- Rename post-bosh-deploy.sh hook into post-deploy.sh [\#99](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/99)
- init pipeline should handle additional teams [\#98](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/98)
- on cf-app deployments \[skip ci\] is ignored on secrets repo updates and builds are triggered twice [\#95](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/95)

**Merged pull requests:**

- task\(generate-manifest\): fixes missing support for vars files in a IAAS\_TYPE dir [\#102](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/102)

## [v1.8.4](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.8.4) (2018-02-07)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.8.3...v1.8.4)

**Implemented enhancements:**

- bump spruce 1.14 - better hybrid spruce / bosh 2 interop [\#70](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/70)

**Closed issues:**

- Terraform update are not detected by depls-pipeline [\#94](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/94)

**Merged pull requests:**

- pipeline\(cf-apps\): injects CF info as environment variable in post-cf-deploy [\#97](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/97)
- pipeline\(depls,s3-br-upload\): supports offline boshrelease and updates boshrelease upload location - REQUIRES shared/private config feature [\#93](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/93)

## [v1.8.3](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.8.3) (2018-01-30)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.8.2...v1.8.3)

## [v1.8.2](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.8.2) (2018-01-23)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.8.1...v1.8.2)

**Implemented enhancements:**

- Update terraform-provider-cloudfoundry version [\#23](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/23)

**Fixed bugs:**

- Failed to commit generated manifest [\#85](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/85)
- Cannot reset wip due to an error about develop branch [\#78](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/78)
- New deployments freeze on first launch [\#29](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/29)

**Closed issues:**

- Avoid same deployment to be executed in parallel [\#86](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/86)

**Merged pull requests:**

- Setup additional teams [\#87](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/87)

## [v1.8.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.8.1) (2018-01-16)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.8.0...v1.8.1)

**Merged pull requests:**

- script\(generate-depls\): supports shared config with override [\#77](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/77)
- pipeline\(depls\): restores terraform scan during update-pipeline [\#76](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/76)

## [v1.8.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.8.0) (2018-01-12)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.7.1...v1.8.0)

**Implemented enhancements:**

- Support ops-files and var-files for \[cloud|runtime\]-config [\#50](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/50)
- Split out pipelines in distinct teams \(concourse ops vs template/secrets contributors\) [\#21](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/21)

**Fixed bugs:**

- \[skip ci\] is ignored on secrets repo updates and builds are triggered twice [\#74](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/74)
- Failed to load root deployment composed only by `disabled` deployment [\#64](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/64)
- Race condition between ops-depls-generated/update-pipeline-ops-depls-generated and  ops-depls-cf-apps-generated [\#19](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/19)

**Merged pull requests:**

- pipeline\(depls\): add new resource to handle git commit [\#75](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/75)
- task\(terraform\_\*\): switch to custom image with providers and bump TF 0.11.2 [\#73](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/73)
- task\(generate\_manifest\): supports vars-file without spruce processing [\#71](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/71)
- pipeline\(depls\): introduces a new staging branch on paas-templates [\#68](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/68)

## [v1.7.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.7.1) (2017-12-08)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.7.0...v1.7.1)

## [v1.7.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.7.0) (2017-12-04)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.6.0...v1.7.0)

**Implemented enhancements:**

- Support iaas specifics on bosh deployment [\#51](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/51)

**Fixed bugs:**

- Bosh deployment using v1 manifest fails with concourse 3.5.\* and 3.6.0 [\#53](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/53)

**Merged pull requests:**

- feature: Support ops-files and var-files for \[cloud|runtime\]-config [\#60](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/60)

## [v1.6.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.6.0) (2017-11-28)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.5.1...v1.6.0)

**Fixed bugs:**

- bosh deployment support for vars property with leading / [\#30](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/30)

**Merged pull requests:**

- pipeline\(depls\): overrides bosh-deployment-resource v1 to latest [\#59](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/59)
- Fix improper input mapping for secrets in tf-pipeline [\#58](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/58)
- Fix Tf pipeline [\#57](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/57)
- pipeline\(depls\): move stemcell support from bosh.io to S3 [\#55](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/55)
- task\(execute\_deploy\_script\): ensure deploy.sh is always executable [\#54](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/54)
- task\(post\_bosh\_deploy\): switch to cf-cli image [\#49](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/49)
- pipeline\(depls\): refactor to extract task variable args into task params [\#48](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/48)
- Tf dev env refinements [\#47](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/47)
- tf only pipeline [\#40](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/40)

## [v1.5.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.5.1) (2017-10-27)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.5.0...v1.5.1)

**Fixed bugs:**

- Adding a deployment without a 'releases' item crash pipeline generatation [\#44](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/44)

**Merged pull requests:**

- Revert: Map the secret full resource to enable tf cross reference oth… [\#46](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/46)
- Map the secret full resource to enable tf cross reference tf state [\#45](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/45)

## [v1.5.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.5.0) (2017-10-26)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.4.1-prod...v1.5.0)

**Merged pull requests:**

- pipeline\(depls\): extract cloud and runtime task to dedicated files [\#43](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/43)
- pipeline\(s3-\*-upload\): add pipeline to upload bosh releases or stemcells to s3 [\#42](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/42)
- pipeline\(depls\): upgrade to bosh-cli-v2 for \[cloud|runtime\]-config [\#41](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/41)

## [v1.4.1-prod](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.4.1-prod) (2017-10-20)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.4.1...v1.4.1-prod)

## [v1.4.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.4.1) (2017-10-19)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.4.0-prod...v1.4.1)

**Implemented enhancements:**

- should be able to skip spruce templating [\#25](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/25)

**Merged pull requests:**

- pipeline\(depls\): support deployment manifest without template [\#37](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/37)
- Don't allow TF to prompt for user input  [\#36](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/36)

## [v1.4.0-prod](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.4.0-prod) (2017-10-06)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.4.0...v1.4.0-prod)

## [v1.4.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.4.0) (2017-10-06)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.3-prod...v1.4.0)

**Fixed bugs:**

- bosh2 operators support is KO [\#33](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/33)

**Closed issues:**

- Include support for bosh ops files  [\#6](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/6)
- Dump recent logs on cf app push failure [\#5](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/5)
- Explicit support for periodic bosh director clean up [\#3](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/3)

**Merged pull requests:**

- Only accept PRs from the original repo [\#26](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/26)
- Upgrading terraform to 0.10.2 and cloudfoundry provider to 0.9.1 [\#24](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/24)
- pipeline\(depls\): introduce active/inactive deployment [\#16](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/16)
- Terraform modules support [\#13](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/13)
- Feature enable pr ci [\#9](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/9)

## [v1.3-prod](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.3-prod) (2017-08-01)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.2.2-prod...v1.3-prod)

## [v1.2.2-prod](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.2.2-prod) (2017-07-18)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.2.1-prod...v1.2.2-prod)

## [v1.2.1-prod](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.2.1-prod) (2017-07-17)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.2.1...v1.2.1-prod)

## [v1.2.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.2.1) (2017-07-17)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.2-prod...v1.2.1)

## [v1.2-prod](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.2-prod) (2017-07-13)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.2...v1.2-prod)

## [v1.2](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.2) (2017-07-13)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/prod-latest...v1.2)

## [prod-latest](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/prod-latest) (2017-07-13)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.1-prod...prod-latest)

## [v1.1-prod](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.1-prod) (2017-07-13)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.1...v1.1-prod)

## [v1.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.1) (2017-07-13)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/prod-stable...v1.1)

## [prod-stable](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/prod-stable) (2017-07-10)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.0...prod-stable)

## [v1.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.0) (2017-07-06)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*