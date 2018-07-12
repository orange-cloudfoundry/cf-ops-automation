# Directory structure 'another-world-root-depls' for  example

## The config repo

### root level overview

```bash
.
|-- hello-world-root-depls
|-- private-config.yml
`-- shared
```

### another-world-root-depls overview

```bash
Inactive deployment: config dir for another-world-root-depls does not exist.
```

## The template repo

### root level overview

```bash
.
|-- another-world-root-depls
|-- hello-world-root-depls
`-- shared-config.yml
```

### another-world-root-depls overview

```bash
another-world-root-depls
|-- another-bosh-deployment-sample
|   |-- deployment-dependencies.yml
|   `-- template
|       |-- adding-ntp-release-operators.yml
|       |-- another-bosh-deployment-sample-tpl.yml
|       |-- ntp-release-vars.yml
|       |-- openstack
|       |   `-- nginx-operators.yml
|       |-- post-deploy.sh
|       `-- pre-deploy.sh
|-- another-world-root-depls-versions.yml
`-- template
    |-- cloud-config-tpl.yml
    |-- deploy.sh
    |-- openstack
    |   `-- disk-types-cloud-operators.yml
    `-- runtime-config-tpl.yml
```

## The config files

### The root config files

* [hello-world-root-depls](/docs/reference_dataset/config_repository/hello-world-root-depls)
* [private-config.yml](/docs/reference_dataset/config_repository/private-config.yml)
* [shared](/docs/reference_dataset/config_repository/shared)

### The another-world-root-depls files


### The shared files

* [shared](/docs/reference_dataset/shared/shared)
  * [certs](/docs/reference_dataset/shared/shared/certs)
    * [internal_paas-ca](/docs/reference_dataset/shared/shared/certs/internal_paas-ca)
      * [server-ca.crt](/docs/reference_dataset/shared/shared/certs/internal_paas-ca/server-ca.crt)
  * [pipeline-credentials.yml](/docs/reference_dataset/shared/shared/pipeline-credentials.yml)
  * [secrets.yml](/docs/reference_dataset/shared/shared/secrets.yml)

## The template files

### The root template files

* [another-world-root-depls](/docs/reference_dataset/template_repository/another-world-root-depls)
* [hello-world-root-depls](/docs/reference_dataset/template_repository/hello-world-root-depls)
* [shared-config.yml](/docs/reference_dataset/template_repository/shared-config.yml)

### The another-world-root-depls files

* [another-world-root-depls](/docs/reference_dataset/template_repository/another-world-root-depls)
  * [another-bosh-deployment-sample](/docs/reference_dataset/template_repository/another-world-root-depls/another-bosh-deployment-sample)
    * [deployment-dependencies.yml](/docs/reference_dataset/template_repository/another-world-root-depls/another-bosh-deployment-sample/deployment-dependencies.yml)
    * [template](/docs/reference_dataset/template_repository/another-world-root-depls/another-bosh-deployment-sample/template)
      * [adding-ntp-release-operators.yml](/docs/reference_dataset/template_repository/another-world-root-depls/another-bosh-deployment-sample/template/adding-ntp-release-operators.yml)
      * [another-bosh-deployment-sample-tpl.yml](/docs/reference_dataset/template_repository/another-world-root-depls/another-bosh-deployment-sample/template/another-bosh-deployment-sample-tpl.yml)
      * [ntp-release-vars.yml](/docs/reference_dataset/template_repository/another-world-root-depls/another-bosh-deployment-sample/template/ntp-release-vars.yml)
      * [openstack](/docs/reference_dataset/template_repository/another-world-root-depls/another-bosh-deployment-sample/template/openstack)
        * [nginx-operators.yml](/docs/reference_dataset/template_repository/another-world-root-depls/another-bosh-deployment-sample/template/openstack/nginx-operators.yml)
      * [post-deploy.sh](/docs/reference_dataset/template_repository/another-world-root-depls/another-bosh-deployment-sample/template/post-deploy.sh)
      * [pre-deploy.sh](/docs/reference_dataset/template_repository/another-world-root-depls/another-bosh-deployment-sample/template/pre-deploy.sh)
  * [another-world-root-depls-versions.yml](/docs/reference_dataset/template_repository/another-world-root-depls/another-world-root-depls-versions.yml)
  * [template](/docs/reference_dataset/template_repository/another-world-root-depls/template)
    * [cloud-config-tpl.yml](/docs/reference_dataset/template_repository/another-world-root-depls/template/cloud-config-tpl.yml)
    * [deploy.sh](/docs/reference_dataset/template_repository/another-world-root-depls/template/deploy.sh)
    * [openstack](/docs/reference_dataset/template_repository/another-world-root-depls/template/openstack)
      * [disk-types-cloud-operators.yml](/docs/reference_dataset/template_repository/another-world-root-depls/template/openstack/disk-types-cloud-operators.yml)
    * [runtime-config-tpl.yml](/docs/reference_dataset/template_repository/another-world-root-depls/template/runtime-config-tpl.yml)

## Required pipeline credentials for another-world-root-depls

### another-world-root-depls-cf-apps-generated.yml

No credentials required

### another-world-root-depls-concourse-generated.yml

No credentials required

### another-world-root-depls-generated.yml

* bosh-client
* bosh-client-secret
* bosh-environment
* bosh-password
* bosh-target
* bosh-username
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* iaas-type
* paas-templates-branch
* paas-templates-uri
* secrets-branch
* secrets-uri
* slack-channel
* slack-webhook

### another-world-root-depls-init-generated.yml

No credentials required

### another-world-root-depls-news-generated.yml

* stemcell-version

### another-world-root-depls-s3-br-upload-generated.yml

* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* concourse-another-world-root-depls-password
* concourse-another-world-root-depls-target
* concourse-another-world-root-depls-username
* slack-channel
* slack-webhook

### another-world-root-depls-s3-stemcell-upload-generated.yml

* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* concourse-another-world-root-depls-password
* concourse-another-world-root-depls-target
* concourse-another-world-root-depls-username
* slack-channel
* slack-webhook

### another-world-root-depls-sync-helper-generated.yml

No credentials required

### another-world-root-depls-tf-generated.yml

No credentials required

## List of pipelines in which credentials appear for another-world-root-depls

### bosh-client

* another-world-root-depls-generated.yml

### bosh-client-secret

* another-world-root-depls-generated.yml

### bosh-environment

* another-world-root-depls-generated.yml

### bosh-password

* another-world-root-depls-generated.yml

### bosh-target

* another-world-root-depls-generated.yml

### bosh-username

* another-world-root-depls-generated.yml

### cf-ops-automation-branch

* another-world-root-depls-generated.yml
* another-world-root-depls-s3-br-upload-generated.yml
* another-world-root-depls-s3-stemcell-upload-generated.yml

### cf-ops-automation-tag-filter

* another-world-root-depls-generated.yml
* another-world-root-depls-s3-br-upload-generated.yml
* another-world-root-depls-s3-stemcell-upload-generated.yml

### cf-ops-automation-uri

* another-world-root-depls-generated.yml
* another-world-root-depls-s3-br-upload-generated.yml
* another-world-root-depls-s3-stemcell-upload-generated.yml

### concourse-another-world-root-depls-password

* another-world-root-depls-s3-br-upload-generated.yml
* another-world-root-depls-s3-stemcell-upload-generated.yml

### concourse-another-world-root-depls-target

* another-world-root-depls-s3-br-upload-generated.yml
* another-world-root-depls-s3-stemcell-upload-generated.yml

### concourse-another-world-root-depls-username

* another-world-root-depls-s3-br-upload-generated.yml
* another-world-root-depls-s3-stemcell-upload-generated.yml

### iaas-type

* another-world-root-depls-generated.yml

### paas-templates-branch

* another-world-root-depls-generated.yml

### paas-templates-uri

* another-world-root-depls-generated.yml

### secrets-branch

* another-world-root-depls-generated.yml

### secrets-uri

* another-world-root-depls-generated.yml

### slack-channel

* another-world-root-depls-generated.yml
* another-world-root-depls-s3-br-upload-generated.yml
* another-world-root-depls-s3-stemcell-upload-generated.yml

### slack-webhook

* another-world-root-depls-generated.yml
* another-world-root-depls-s3-br-upload-generated.yml
* another-world-root-depls-s3-stemcell-upload-generated.yml

### stemcell-version

* another-world-root-depls-news-generated.yml

