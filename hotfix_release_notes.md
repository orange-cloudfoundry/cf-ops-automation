#Hotfix release
## [v1.7.2](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v1.7.2)

**Fixed bugs:**

- unexpected bosh-cli-v2 image upgrade broke cloud and runtime config support. So instead of using the latest version, we use a specific docker image version.
