#Hotfix release
## [v3.1.1](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v3.1.1)

**Fixed bugs:**

- deployment-dependencies per iaas_type support is broken [\#204](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/204)

- multiple concurrent executions of bosh errands [\#194](https://github.com/orange-cloudfoundry/cf-ops-automation/issues/194)

**Enhancements:**

- bump providers: azure, aws, cloudflare, cloudfoundry, credhub, flexible-engine, kubernetes and openstack. See https://github.com/orange-cloudfoundry/paas-docker-cloudfoundry-tools/commit/c1f95e84451a6f9935254d85624a128611ccc9d9

- pipeline(depls): add mutex on terraform plan and apply to avoid inconsistency when plan and apply run at the same time

- upgrade(coa_version_update): add script to ease switch to a coa corrective version
