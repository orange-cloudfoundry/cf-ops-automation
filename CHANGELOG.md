# Changelog

## [v6.2.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v6.2.0) (2024-05-14)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v6.1.3...v6.2.0)

**Fixed bugs:**

- Precompile pipeline handle bosh error during push-bosh job in repackage-releases-fallback task [\#442](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/442)
- Properly detect errors in precompile pipelines [\#439](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/439)

**Miscellaneous:**

- bump coa-ci to concourse 7.10 [\#441](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/441)

**Merged pull requests:**

- chore\(deps\): update paas-docker-cloudfoundry-tools commit-id to 0812269 [\#448](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/448)
- switch to elpaasoci images [\#446](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/446)
- chore\(deps\): update paas-docker-cloudfoundry-tools commit-id to bbe33e0 [\#444](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/444)
- tasks\(repackage\_boshreleases\_fallback\): fix deserialization [\#443](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/443)
- chore\(deps\): update devtest tools [\#440](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/440)
- chore\(deps\): update paas-docker-cloudfoundry-tools commit-id to ee3c5be [\#433](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/433)

## [v6.1.3](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v6.1.3) (2023-08-21)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v6.1.2...v6.1.3)

## [v6.1.2](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v6.1.2) (2023-08-16)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v6.1.1...v6.1.2)

**Implemented enhancements:**

- pipeline\(precompile\): allow configuration to force local compilation on bosh director [\#438](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/438)

## [v6.1.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v6.1.1) (2023-08-10)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v6.1.0...v6.1.1)

**Implemented enhancements:**

- pipeline\(precompile\): detect blobstore related errors [\#435](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/435)

**Fixed bugs:**

- pipeline\(precompile\): refine blobstore related error detection [\#437](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/437)
- feature\(easily-identify-precompile-deployments\): restore this feature [\#436](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/436)

**Merged pull requests:**

- chore\(deps\): update devtest tools [\#434](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/434)

## [v6.1.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v6.1.0) (2023-06-13)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v6.0.5...v6.1.0)

**Implemented enhancements:**

- Rework logging mechanisms [\#417](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/417)
- pipeline\(bosh\): fine grain management of compiled download url [\#416](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/416)

**Fixed bugs:**

- precompile pipeline manage bosh release defined in runtime config [\#412](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/412)

**Miscellaneous:**

- Update COA CI env [\#415](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/415)

**Closed issues:**

- Contact SNCF [\#394](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/394)

**Merged pull requests:**

- chore\(deps\): update dependency rubocop to '~\> 1.52.1' [\#430](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/430)
- chore\(deps\): update devtest tools [\#429](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/429)
- chore\(deps\): update devtest tools [\#428](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/428)
- chore\(deps\): update dependency cloudfoundry/bosh-cli to v7.2.3 [\#427](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/427)
- chore\(deps\): update paas-docker-cloudfoundry-tools commit-id to 4c45660 [\#420](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/420)
- move to elpaasoci based images [\#414](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/414)

## [v6.0.5](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v6.0.5) (2023-02-28)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v6.0.4...v6.0.5)

## [v6.0.4](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v6.0.4) (2023-02-27)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v6.0.3...v6.0.4)

**Merged pull requests:**

- pipeline\(precompile\): fix missing release upload without precompile [\#411](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/411)

## [v6.0.3](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v6.0.3) (2023-01-13)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v6.0.2...v6.0.3)

**Merged pull requests:**

- pipeline\(precompile\): fix already compile bosh release detection [\#409](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/409)
- pipeline\(k8s\): fix re-trigger all jobs [\#408](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/408)

## [v6.0.2](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v6.0.2) (2022-12-14)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v6.0.0...v6.0.2)

**Fixed bugs:**

- concourse\(bosh-precompile\): ensure stemcell upload [\#406](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/406)

## [v6.0.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v6.0.0) (2022-10-19)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v5.4.0...v6.0.0)

**Implemented enhancements:**

- support multi root deployment pipelines [\#404](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/404)
- bump ruby to 3.1.2 [\#402](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/402)
- feature\(easily-identify-precompile-deployments\) [\#400](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/400)
- feature: externalize control plane audit trail [\#399](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/399)

**Miscellaneous:**

- chore\(ci\): downsize flavor used in test [\#403](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/403)
- chore\(ci\): bump to concourse 7.8.2 and bosh-cli 6.4.17 [\#401](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/401)

**Merged pull requests:**

- concourse\(pipelines\): polishing unpause mechanism [\#405](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/405)

## [v5.4.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v5.4.0) (2022-06-02)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v5.3.0...v5.4.0)

**Implemented enhancements:**

- explicit concourse job failure when terraform plan exhibits discrepancy [\#344](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/344)
- polish pipelines [\#393](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/393)
- bump to latest images [\#392](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/392)
- feature\(bosh-pipeline\): display terraform status [\#388](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/388)

**Fixed bugs:**

- pipeline\(bosh\): fix meta-inf.yml detection [\#391](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/391)

**Security fixes:**

- switch pipelines and tasks to our images [\#386](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/386)

**Merged pull requests:**

- pipeline\(bosh\): disable exported\_from [\#398](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/398)
- Detect stemcell upload errors during precompile [\#397](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/397)
- feature\(bosh-pipeline\): inject coa-metadata [\#389](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/389)
- add-display-background: support pipeline background customization [\#387](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/387)

## [v5.3.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v5.3.0) (2022-01-04)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v5.2.2...v5.3.0)

**Implemented enhancements:**

- Include git metadata in bosh manifest [\#381](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/381)
- pipelines\(control-plane|update\): use fly to format pipelines [\#383](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/383)
- fix missing scanned files and concourse bump [\#380](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/380)

**Fixed bugs:**

- tasks\(bosh\_upload\_stemcell\): detect errors during stemcell upload [\#385](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/385)
- pipelines\(bosh\): remove commit message from bosh tags [\#384](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/384)
- pipelines\(bosh\): fix git info into bosh manifest injection [\#382](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/382)
- customize-reconciliation-loop-interval [\#379](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/379)

## [v5.2.2](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v5.2.2) (2021-08-26)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v5.2.1...v5.2.2)

**Merged pull requests:**

- k8s support enhancements [\#378](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/378)

## [v5.2.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v5.2.1) (2021-08-23)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v5.1.0...v5.2.1)

**Implemented enhancements:**

- Refactor offline bosh release management [\#264](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/264)

**Miscellaneous:**

- test\(integration-tests\): switch to ibm cloud [\#366](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/366)
- Concourse 7.2 bump [\#365](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/365)

**Closed issues:**

- Add rate limiting on bosh release precompilations  [\#372](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/372)

**Merged pull requests:**

- pipeline\(\*\): bump tools in docker images [\#377](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/377)
- feature\(rate-limiting-on-bosh-release-precompile\): [\#376](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/376)
- feature\(configure-concourse-retry\): enhance concourse retry management [\#375](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/375)
- build\(deps\): bump addressable from 2.7.0 to 2.8.0 [\#374](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/374)
- pipelines\(bosh\): remove recreate-all support [\#373](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/373)
- chore\(ci\): update test image to concourse 7.3.2 [\#371](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/371)
- pipelines\(bosh\): clear sha1 for offline releases [\#370](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/370)
- avoid usage of latest tag for docker image [\#369](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/369)
- single upload job for stemcell upload [\#368](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/368)
- switch to 'registry-image' [\#367](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/367)

## [v5.1.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v5.1.0) (2021-01-25)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v5.0.3...v5.1.0)

**Implemented enhancements:**

- CF7 & Cf app zero downtime deployment  [\#329](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/329)
- generate bosh compiled release pipeline [\#88](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/88)
- feature\(minimal-kubernetes-support\): fix pipeline without deployment [\#353](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/353)
- feature\(minimal-kubernetes-support\): introduce new pipeline to support k8s files [\#352](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/352)
- Bump docker images [\#337](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/337)

**Miscellaneous:**

- CI: bump to concourse 6.7.1 [\#354](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/354)

**Closed issues:**

- cf app support lacks ability to define CF CLI environment variables to tune cf push behavior [\#240](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/240)

**Merged pull requests:**

- feature\(tune-cf-push-options\): allow cf push customization [\#357](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/357)
- pipeline\(bosh|precompile\): fix stemcell version consistency [\#356](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/356)
-  feature\(bosh-director-pull-mode\): implement for bosh pipelines only [\#355](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/355)

## [v5.0.3](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v5.0.3) (2020-10-05)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v5.0.2...v5.0.3)

**Merged pull requests:**

- pipeline\(bosh-precompile\): only use templates to generate pipeline [\#351](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/351)
- fix\(resolve-manifest-version\): handle properly multiple stemcell definition [\#350](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/350)

## [v5.0.2](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v5.0.2) (2020-09-25)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v5.0.1...v5.0.2)

**Merged pull requests:**

- pipeline\(sync-feature-branches\): fix missing untrusted certificates support [\#349](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/349)

## [v5.0.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v5.0.1) (2020-09-16)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v5.0.0...v5.0.1)

## [v5.0.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v5.0.0) (2020-09-15)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v4.3.2...v5.0.0)

**Implemented enhancements:**

- cloud-config and runtime-config credhub interpolation should not block [\#331](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/331)

**Fixed bugs:**

- precompilation should manage per iaas-type bosh release [\#345](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/345)

**Merged pull requests:**

- feature\(concourse-6.5.0-support\): bump concourse pipeline resource [\#348](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/348)
- pipeline\(bosh-precompile\): split single deployment into dedicated deployments [\#346](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/346)
- pipeline\(bosh-precompile\): fix pipeline team [\#342](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/342)
- chore\(ci\): bump to concourse 6.4 and bosh-cli 6.2.1 [\#341](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/341)
- feature\(multi-concourse-version-compliant-pipelines\): update pipelines to be able to run it on concourse 5.8.x and concourse 6.4.x [\#340](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/340)
- feature\(support-release-repackaging-fallback\): direct download from bosh.io for releases with repackaging errors [\#339](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/339)
- restrict managed versions [\#336](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/336)
- feature\(allow-incomplete-crehub-interpolation\): [\#332](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/332)
- feature\(boshrelease-offline-support-rework\) [\#330](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/330)
- Generate compiled release [\#319](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/319)

## [v4.3.2](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v4.3.2) (2020-04-10)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v4.3.1...v4.3.2)

**Implemented enhancements:**

- fix\(git-shallow-clone\): automatically disable git shallow clone for concourse pipelines when submodules are used [\#328](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/328)
- feature\(lower-concourse-database-usage\): switch metadata resource type [\#327](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/327)

**Merged pull requests:**

- feature: ease shared secrets triggering debug [\#326](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/326)

## [v4.3.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v4.3.1) (2020-03-31)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v4.3.0...v4.3.1)

**Implemented enhancements:**

- feature\(disable-recursive-submodule-checkout\): implements this feature for bosh pipelines [\#325](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/325)
- feature\(git-shallow-clone\): change git resource configuration to reduce git server workload [\#322](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/322)

**Fixed bugs:**

- Tfstate changes not detected after tf apply [\#323](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/323)
- Improve secrets repository update robustness [\#320](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/320)
- Fix tfstate change detection [\#324](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/324)
- pipeline\(bosh\): add retry on secrets repository push [\#321](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/321)

## [v4.3.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v4.3.0) (2020-03-16)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v4.2.0...v4.3.0)

**Implemented enhancements:**

- bump terraform flexible engine to version 1.11 [\#308](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/308)
- Quick overview of bosh release versions used by a root deployment  [\#305](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/305)
- Leverage icons to ease resource identification [\#304](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/304)
- multiple markers for iaas-type \(~ profile tag\) [\#79](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/79)

**Closed issues:**

- Replace deprecated docker images [\#303](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/303)
- Support concourse latest version \(5.8.x\) [\#299](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/299)
- delete lifecyle does not clean up generated bosh manifest in secrets repo [\#65](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/65)

**Merged pull requests:**

- fix\(manifest-bosh-deployment-information\): add optional resource to have deployment\_information file available [\#318](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/318)
- feature\(display-bosh-deployment-information\) [\#317](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/317)
- fix\(bootstrap-all-init-pipeline\): replace curl by wget [\#316](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/316)
- refactor\(rubocop\): fix warnings [\#315](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/315)
- fix\(bootstrap-all-init-pipeline\): auto detect credentials files [\#314](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/314)
- feature\(bosh-delete-deployment\): fail-slow, to delete as much deployments as possible [\#313](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/313)
- feature\(remove-spiff-references\): as spiff image is not used anymore, it is not required to keep such references [\#311](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/311)
- Support auto sorted profiles [\#310](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/310)
- Bump images from orange-cloudfoundry/paas-docker-cloudfoundry-tools [\#309](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/309)
- Support profiles [\#306](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/306)
- feature\(concourse\): support concourse 5.8 [\#302](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/302)
- chore\(gem\): bump to latest gem \(rspec, simplecov, github\_changelog\_generator, ...\) [\#301](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/301)

## [v4.2.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v4.2.0) (2020-01-08)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v4.1.0...v4.2.0)

**Implemented enhancements:**

- Customize the errand name displayed on concourse job box [\#296](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/296)
- credhub interpolation for cloud-config and runtime-config [\#290](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/290)
- support cpi-config files [\#191](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/191)
- Add support for multiple errands \(automatic and manual ones\) [\#14](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/14)

**Closed issues:**

- Bump cf cli to 6.47.2 [\#292](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/292)
- bosh errands should trigger after each bosh deploy [\#285](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/285)
- Full private docker registry support [\#278](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/278)
- Polluting trace in cloud-config-and-runtime-config-for-xx-depls/update-cloud-config-for-micro-depls run.sh [\#265](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/265)
- Bump to latest Ruby 2.6.x and alpine 3.9 [\#260](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/260)
- COA CI Iaas Migration [\#229](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/229)
- delete-lifecyle does not support clean up of paas-template instances [\#67](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/67)

**Merged pull requests:**

- task\(bosh\_delete\_\*\): enhance log messages [\#300](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/300)
- feature\(bosh-pipeline\): enhance templates repository instances automatic cleanup [\#298](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/298)
- feature\(bosh-pipeline\): support errand name customization [\#297](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/297)
- feature\(bosh-pipelines\): detect inconsistent boshrelease detect-inconsistent-boshrelease-definitions [\#295](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/295)
- Full private docker registry support [\#294](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/294)
- feature\(cf-app\): bump cf cli version [\#293](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/293)
- Rework cloud and runtime config support [\#291](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/291)

## [v4.1.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v4.1.0) (2019-11-04)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v4.0.4...v4.1.0)

**Implemented enhancements:**

- bump cf cli 6.46.1 in cf app support [\#257](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/257)

**Closed issues:**

- Bump spruce 1.22 [\#283](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/283)
- Bump terraform 0.11.14 [\#277](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/277)
- Ensure deployment consistency [\#276](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/276)
- Support meta information defined in templates repository [\#275](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/275)

**Merged pull requests:**

- feature\(bosh-pipeline\): add manual-errand support and multi job errands [\#286](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/286)
- Improve wording of error message [\#282](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/282)
- Fix invalid relative path in reference documentation [\#281](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/281)

## [v4.0.4](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v4.0.4) (2019-10-04)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v4.0.3...v4.0.4)

## [v4.0.3](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v4.0.3) (2019-10-03)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v4.0.2...v4.0.3)

**Fixed bugs:**

- broken link in bosh deployment template operators silently ignored [\#273](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/273)

## [v4.0.2](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v4.0.2) (2019-08-07)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v4.0.0...v4.0.2)

## [v4.0.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v4.0.0) (2019-07-29)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v3.6.0...v4.0.0)

**Fixed bugs:**

- Custom teams cannot be used anymore [\#215](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/215)
- control-plane/save-deployed-pipelines: excessive job triggering  [\#206](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/206)

**Closed issues:**

- Support Concourse v4.x/v5.x \(expected perf improvements\) [\#178](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/178)

**Merged pull requests:**

- cleanup old pipelines [\#271](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/271)
- upgrade to concourse 5 [\#261](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/261)

## [v3.6.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v3.6.0) (2019-06-28)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v3.6.1...v3.6.0)

## [v3.6.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v3.6.1) (2019-06-28)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v3.5.0...v3.6.1)

**Closed issues:**

- Detect potential conflicts between feature branches as soon as possible [\#267](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/267)
- Run deploy script on each commit [\#262](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/262)

**Merged pull requests:**

- chore\(build\): bump gems to latest \(docker\_registry2, rubocop, rspec and simplecov\) [\#270](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/270)
- pipeline\(bosh\): execute deploy script on each commit [\#269](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/269)
- pipeline\(concourse\): allow credentials sharing between generated pipelines and custom pipelines [\#268](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/268)

## [v3.5.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v3.5.0) (2019-06-04)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v3.4.1...v3.5.0)

**Implemented enhancements:**

- recreate pipelines should use --fix flag to deal with connectivity errors [\#250](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/250)

**Closed issues:**

- Document & test relative paths for spruce file inclusion [\#255](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/255)
- Partial private docker registry support [\#254](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/254)
- Optional secrets scan to reduce git workload [\#248](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/248)
- Support proxy for slack-notification [\#148](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/148)

**Merged pull requests:**

- doc\(reference-dataset\): document spruce file usage [\#258](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/258)
- pipeline\(\*\): support proxy for slack-notification [\#253](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/253)
- Optional secrets scans Fixes and supports a private docker registry [\#252](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/252)
- Bosh recreate fix [\#251](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/251)

## [v3.4.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v3.4.1) (2019-03-28)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v3.4.0...v3.4.1)

**Implemented enhancements:**

- Dump generated manifest on bosh deploy failures [\#2](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/2)

**Fixed bugs:**

- committed generated cloud-config.yml and runtime-config.yml are incomplete [\#246](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/246)

**Closed issues:**

- Issue with the "github-release" concourse resource type tagged versions. [\#220](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/220)

## [v3.4.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v3.4.0) (2019-03-15)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v3.3.0...v3.4.0)

**Implemented enhancements:**

- Record bosh deployment manifest including ops files interpolation [\#242](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/242)
- git submodule of a deployment model are not pulled in the on-demand-pipeline context   [\#195](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/195)

**Fixed bugs:**

- runtime-config operators are not applied in alphabetic order [\#244](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/244)
- fe-int default value is not generic [\#243](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/243)

**Closed issues:**

- 1st class support for private bosh releases [\#81](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/81)

**Merged pull requests:**

- pipeline\(bosh\): improvements [\#247](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/247)
- tasks\(bosh\_update\_\[cloud|runtime\]\_config: fix operator alphabetical order when applied [\#245](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/245)
- hardening pipeline retries [\#241](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/241)
- pipelines\(submodules\): fix  [\#237](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/237)
- 108 add covered pipelines [\#236](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/236)
- Load submodules from the PaaS Template repo in the BOSH pipeline [\#230](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/230)

## [v3.3.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v3.3.0) (2019-01-22)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v3.2.2...v3.3.0)

**Implemented enhancements:**

- add a retrigger all job on \*-depls-s3-br-upload-generated pipelines [\#202](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/202)
- UX: Include update-pipeline-ops-depls-generated job in tf group  [\#18](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/18)
- Rename check-terraform-cf-consistency  [\#11](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/11)

**Fixed bugs:**

- Parallel execution limit seems to generate deadlocks in some cases [\#216](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/216)

**Closed issues:**

- Error during git put tasks leads to data loss \(eg tfstate changes\) [\#232](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/232)
- Allow users to provide a GitHub access token for the "github-release" concourse resource type. [\#219](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/219)
- reset-merged-wip-features job doesn't apply the configuration from GIT [\#218](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/218)
- bootstrap failed to dynamically create vars\_files list for \*-update-pipeline  [\#213](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/213)
- multiple concurrent executions of bosh errands [\#196](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/196)

**Merged pull requests:**

- Reorganize libs [\#227](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/227)
- logger\(\*\): fix the logger so that it works for class methods. [\#226](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/226)
- pipelines\(br-upload\): add a retrigger-all-uploads task [\#225](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/225)
- 81 add ops interpolation example [\#224](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/224)
- pipeline\(sync-feature-branches\): add hard reset job [\#222](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/222)
- 220 github-release resource type [\#221](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/221)
- WIP: rework serial\_groups allocation [\#217](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/217)
- Fix bootstrap failure on update-pipeline [\#214](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/214)
- This features extend the existing tests by making use of the refence dataset [\#190](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/190)

## [v3.2.2](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v3.2.2) (2018-11-23)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v3.2.0...v3.2.2)

**Fixed bugs:**

- Dual mode jobs are broken on bootstrap-all-init-pipeline  [\#209](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/209)

**Closed issues:**

- Root-deployment concurrent execution limit overriding is broken for bosh-pipeline [\#210](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/210)

## [v3.2.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v3.2.0) (2018-11-22)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v3.1.2...v3.2.0)

**Closed issues:**

- Limit concurrent updates that trigger overload and cascading failures [\#184](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/184)

**Merged pull requests:**

- pipeline\(\*\): introduce concurrent update limitations [\#208](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/208)
- Document source of docker image used for terraform [\#198](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/198)
- bosh config server / credhub variables fingerprint [\#194](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/194)
- 12 non bosh io boshrelease support [\#179](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/179)

## [v3.1.2](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v3.1.2) (2018-11-21)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v3.1.1...v3.1.2)

## [v3.1.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v3.1.1) (2018-11-19)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v3.1.0...v3.1.1)

**Implemented enhancements:**

- bosh config server / credhub variables fingerprint [\#72](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/72)
- First class support for public bosh release not hosted on bosh.io [\#12](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/12)

**Fixed bugs:**

- Bosh recreate is broken [\#205](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/205)
- Deployment-dependencies per iaas\_type support is broken [\#204](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/204)
- warning: inexact rename detection was skipped due to too many files. [\#203](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/203)
- Errand jobs failed with ` no versions of image available` [\#199](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/199)

## [v3.1.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v3.1.0) (2018-09-18)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v3.0.0...v3.1.0)

**Implemented enhancements:**

- add features to purge bosh tasks in a root deployment [\#90](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/90)

**Closed issues:**

- Reference Dataset links are broken [\#192](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/192)

**Merged pull requests:**

- pipeline\(depls\): fix invalid bosh-errand-resource [\#200](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/200)
- depls\(utils\) change bosh cancel all tasks vars to bosh cl1 v1 [\#193](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/193)
- create a utils task to cancel all running bosh tasks [\#176](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/176)

## [v3.0.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v3.0.0) (2018-08-09)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v2.2.0...v3.0.0)

**Implemented enhancements:**

- add documentation for bosh deployments recreate pipeline [\#124](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/124)
- Concourse pipeline input bosh releases should be configurable by iaas-type [\#89](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/89)

**Closed issues:**

- Terraform helm support [\#180](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/180)
- Find and apply global solution to print password in yaml files [\#145](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/145)
- provide automated non-attended COA env bootstrap [\#113](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/113)

**Merged pull requests:**

- tasks\(generate\_manifest\): make files used by spruce optional [\#177](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/177)
- support iaas-type for deployement-dependencies [\#175](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/175)
- 145 yaml passwords [\#167](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/167)
- bootstrap-coa-env\(\*\) [\#164](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/164)

## [v2.2.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v2.2.0) (2018-07-24)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v2.1.0...v2.2.0)

**Implemented enhancements:**

- Support online stemcell [\#128](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/128)
- Support terraform provider UAA [\#120](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/120)
- Terraform pipeline UX: single job to apply TF specs [\#22](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/22)

**Fixed bugs:**

- The job update-pipeline-\<root deployment\> is not triggered as expected [\#172](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/172)

**Closed issues:**

- Reset git to a previous commit [\#173](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/173)
- terraform plan phase should not be recurrent daily, but triggered by secrets update [\#156](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/156)
- add terraform azure support [\#153](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/153)
- Regression: IAAS\_SPEC\_PATH is missing in Concourse pipelines  [\#151](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/151)
- Remove consistency check on deployment-dependencies.yml\#deployment.\<dep\_name\> [\#150](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/150)
- Setup a reference dataset [\#111](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/111)
- Add living user documentation generated from tests [\#107](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/107)

**Merged pull requests:**

- task\(git\_reset\_wip\): create a commit after reset [\#174](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/174)
- trigger update-pipeline on each`secrets-repo` commit and `init-concourse-boshrelease-and-stemcell` improvements [\#171](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/171)
- Online stemcells support [\#169](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/169)
- Terraform improvements [\#166](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/166)
- allow usage of generic key in deployment-dependencies [\#163](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/163)
- Living doc missing cf app hooks [\#161](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/161)
- Upgrade script for config repo for upcoming release 2.2.0 [\#160](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/160)
- pipeline\(depls\): collapse delete task to speed up concourse execution [\#154](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/154)
- 107 living documentation refactored [\#149](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/149)

## [v2.1.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v2.1.0) (2018-06-20)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.9.1...v2.1.0)

**Implemented enhancements:**

- offer a preview in logs of interpolated \(manifest + operators + vars\) [\#52](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/52)
- Add delete lifecycle [\#4](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/4)

**Merged pull requests:**

- pipeline\(tf\): fixes missing `IAAS_SPEC_PATH` [\#152](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/152)
- Add task displaying manifest before it gets deployed [\#142](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/142)

## [v1.9.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.9.1) (2018-05-29)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v2.0.0...v1.9.1)

## [v2.0.0](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v2.0.0) (2018-05-29)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.9.0...v2.0.0)

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

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.7.2...v1.7.3)

## [v1.7.2](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.7.2) (2018-02-22)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.8.4...v1.7.2)

**Closed issues:**

- S3 upload pipeline should handle additional teams [\#100](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/100)
- Rename post-bosh-deploy.sh hook into post-deploy.sh [\#99](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/99)
- init pipeline should handle additional teams [\#98](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/98)
- on cf-app deployments \[skip ci\] is ignored on secrets repo updates and builds are triggered twice [\#95](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/95)

**Merged pull requests:**

- task\(generate-manifest\): fixes missing support for vars files in a IAAS\_TYPE dir [\#102](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/102)
- pipeline\(depls,s3-br-upload\): supports offline boshrelease and updates boshrelease upload location - REQUIRES shared/private config feature [\#93](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/93)

## [v1.8.4](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.8.4) (2018-02-07)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.8.3...v1.8.4)

**Implemented enhancements:**

- bump spruce 1.14 - better hybrid spruce / bosh 2 interop [\#70](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/70)

**Closed issues:**

- Terraform update are not detected by depls-pipeline [\#94](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/94)

**Merged pull requests:**

- pipeline\(cf-apps\): injects CF info as environment variable in post-cf-deploy [\#97](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/97)

## [v1.8.3](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.8.3) (2018-01-30)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.8.2...v1.8.3)

**Merged pull requests:**

- Setup additional teams [\#87](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/87)

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

- script\(generate-depls\): supports shared config with override [\#77](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/77)

## [v1.8.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.8.1) (2018-01-16)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.8.0...v1.8.1)

**Merged pull requests:**

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
- task\(post\_bosh\_deploy\): switch to cf-cli image [\#49](https://github.com/orange-cloudfoundry/cf-ops-automation/pull/49)

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

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.4.5...v1.4.1-prod)

## [v1.4.5](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.4.5) (2017-10-20)

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/v1.4.1...v1.4.5)

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

[Full Changelog](https://github.com/orange-cloudfoundry/cf-ops-automation/compare/0cdbc6a9abbb62b8a5ab20d976d232204ec38dd2...v1.0)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
