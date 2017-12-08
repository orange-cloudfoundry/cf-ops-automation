# Change Log

## [v1.7.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.7.1) (2017-12-08)
[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.7.0...v1.7.1)

**Implemented enhancements:**

- Support ops-files and var-files for \[cloud|runtime\]-config [\#50](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/50)

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