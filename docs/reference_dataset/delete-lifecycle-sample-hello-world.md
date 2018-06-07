# Directory structure 'delete-lifecycle-sample' for 'hello-world' example

## The config repo

```bash
.
├── ci-deployment-overview.yml
└── nginx
    └── secrets
        ├── meta.yml
        └── secrets.yml
```

## The template repo

```bash
.
├── delete-lifecycle-sample-versions.yml
├── nginx
│   ├── deployment-dependencies.yml
│   └── template
│       ├── adding-ntp-release-operators.yml
│       ├── nginx-tpl.yml
│       ├── ntp-release-vars.yml
│       ├── openstack
│       │   └── nginx-operators.yml
│       ├── post-deploy.sh
│       └── pre-deploy.sh
└── template
    ├── cloud-config-tpl.yml
    ├── deploy.sh
    ├── openstack
    │   └── disk-types-cloud-operators.yml
    └── runtime-config-tpl.yml
```

## The config files

* [ci-deployment-overview.yml](/docs/reference_dataset/config_repository/hello-world/delete-lifecycle-sample/ci-deployment-overview.yml)
* [nginx](/docs/reference_dataset/config_repository/hello-world/delete-lifecycle-sample/nginx)
  * [secrets](/docs/reference_dataset/config_repository/hello-world/delete-lifecycle-sample/nginx/secrets)
    * [meta.yml](/docs/reference_dataset/config_repository/hello-world/delete-lifecycle-sample/nginx/secrets/meta.yml)
    * [secrets.yml](/docs/reference_dataset/config_repository/hello-world/delete-lifecycle-sample/nginx/secrets/secrets.yml)

## The template files

* [delete-lifecycle-sample-versions.yml](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/delete-lifecycle-sample-versions.yml)
* [nginx](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/nginx)
  * [deployment-dependencies.yml](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/nginx/deployment-dependencies.yml)
  * [template](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/nginx/template)
    * [adding-ntp-release-operators.yml](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/nginx/template/adding-ntp-release-operators.yml)
    * [nginx-tpl.yml](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/nginx/template/nginx-tpl.yml)
    * [ntp-release-vars.yml](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/nginx/template/ntp-release-vars.yml)
    * [openstack](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/nginx/template/openstack)
      * [nginx-operators.yml](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/nginx/template/openstack/nginx-operators.yml)
    * [post-deploy.sh](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/nginx/template/post-deploy.sh)
    * [pre-deploy.sh](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/nginx/template/pre-deploy.sh)
* [template](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/template)
  * [cloud-config-tpl.yml](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/template/cloud-config-tpl.yml)
  * [deploy.sh](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/template/deploy.sh)
  * [openstack](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/template/openstack)
    * [disk-types-cloud-operators.yml](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/template/openstack/disk-types-cloud-operators.yml)
  * [runtime-config-tpl.yml](/docs/reference_dataset/template_repository/hello-world/delete-lifecycle-sample/template/runtime-config-tpl.yml)

## Required pipeline credentials for delete-lifecycle-sample

### delete-lifecycle-sample-cf-apps-generated.yml

No credentials required

### delete-lifecycle-sample-concourse-generated.yml

No credentials required

### delete-lifecycle-sample-generated.yml

* slack-webhook
* secrets-uri
* secrets-branch
* paas-templates-uri
* paas-templates-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* concourse-delete-lifecycle-sample-target
* concourse-delete-lifecycle-sample-insecure
* concourse-delete-lifecycle-sample-username
* concourse-delete-lifecycle-sample-password
* slack-channel
* bosh-target
* bosh-username
* bosh-password
* iaas-type

### delete-lifecycle-sample-init-generated.yml

* slack-webhook
* concourse-delete-lifecycle-sample-target
* concourse-delete-lifecycle-sample-insecure
* concourse-delete-lifecycle-sample-username
* concourse-delete-lifecycle-sample-password
* secrets-uri
* secrets-branch
* paas-templates-uri
* paas-templates-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel

### delete-lifecycle-sample-news-generated.yml

* stemcell-version

### delete-lifecycle-sample-s3-br-upload-generated.yml

* slack-webhook
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel
* concourse-delete-lifecycle-sample-target
* concourse-delete-lifecycle-sample-username
* concourse-delete-lifecycle-sample-password

### delete-lifecycle-sample-s3-stemcell-upload-generated.yml

* slack-webhook
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel
* concourse-delete-lifecycle-sample-target
* concourse-delete-lifecycle-sample-username
* concourse-delete-lifecycle-sample-password

### delete-lifecycle-sample-sync-helper-generated.yml

* slack-webhook
* anonymized-secrets-repo-uri
* anonymized-secrets-compare-repo-uri
* secrets-uri
* secrets-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel

### delete-lifecycle-sample-tf-generated.yml

No credentials required

## List of pipelines in which credentials appear for delete-lifecycle-sample

### slack-webhook

* delete-lifecycle-sample-generated.yml
* delete-lifecycle-sample-init-generated.yml
* delete-lifecycle-sample-s3-br-upload-generated.yml
* delete-lifecycle-sample-s3-stemcell-upload-generated.yml
* delete-lifecycle-sample-sync-helper-generated.yml

### secrets-uri

* delete-lifecycle-sample-generated.yml
* delete-lifecycle-sample-init-generated.yml
* delete-lifecycle-sample-sync-helper-generated.yml

### secrets-branch

* delete-lifecycle-sample-generated.yml
* delete-lifecycle-sample-init-generated.yml
* delete-lifecycle-sample-sync-helper-generated.yml

### paas-templates-uri

* delete-lifecycle-sample-generated.yml
* delete-lifecycle-sample-init-generated.yml

### paas-templates-branch

* delete-lifecycle-sample-generated.yml
* delete-lifecycle-sample-init-generated.yml

### cf-ops-automation-uri

* delete-lifecycle-sample-generated.yml
* delete-lifecycle-sample-init-generated.yml
* delete-lifecycle-sample-s3-br-upload-generated.yml
* delete-lifecycle-sample-s3-stemcell-upload-generated.yml
* delete-lifecycle-sample-sync-helper-generated.yml

### cf-ops-automation-branch

* delete-lifecycle-sample-generated.yml
* delete-lifecycle-sample-init-generated.yml
* delete-lifecycle-sample-s3-br-upload-generated.yml
* delete-lifecycle-sample-s3-stemcell-upload-generated.yml
* delete-lifecycle-sample-sync-helper-generated.yml

### cf-ops-automation-tag-filter

* delete-lifecycle-sample-generated.yml
* delete-lifecycle-sample-init-generated.yml
* delete-lifecycle-sample-s3-br-upload-generated.yml
* delete-lifecycle-sample-s3-stemcell-upload-generated.yml
* delete-lifecycle-sample-sync-helper-generated.yml

### concourse-delete-lifecycle-sample-target

* delete-lifecycle-sample-generated.yml
* delete-lifecycle-sample-init-generated.yml
* delete-lifecycle-sample-s3-br-upload-generated.yml
* delete-lifecycle-sample-s3-stemcell-upload-generated.yml

### concourse-delete-lifecycle-sample-insecure

* delete-lifecycle-sample-generated.yml
* delete-lifecycle-sample-init-generated.yml

### concourse-delete-lifecycle-sample-username

* delete-lifecycle-sample-generated.yml
* delete-lifecycle-sample-init-generated.yml
* delete-lifecycle-sample-s3-br-upload-generated.yml
* delete-lifecycle-sample-s3-stemcell-upload-generated.yml

### concourse-delete-lifecycle-sample-password

* delete-lifecycle-sample-generated.yml
* delete-lifecycle-sample-init-generated.yml
* delete-lifecycle-sample-s3-br-upload-generated.yml
* delete-lifecycle-sample-s3-stemcell-upload-generated.yml

### slack-channel

* delete-lifecycle-sample-generated.yml
* delete-lifecycle-sample-init-generated.yml
* delete-lifecycle-sample-s3-br-upload-generated.yml
* delete-lifecycle-sample-s3-stemcell-upload-generated.yml
* delete-lifecycle-sample-sync-helper-generated.yml

### bosh-target

* delete-lifecycle-sample-generated.yml

### bosh-username

* delete-lifecycle-sample-generated.yml

### bosh-password

* delete-lifecycle-sample-generated.yml

### iaas-type

* delete-lifecycle-sample-generated.yml

### stemcell-version

* delete-lifecycle-sample-news-generated.yml

### anonymized-secrets-repo-uri

* delete-lifecycle-sample-sync-helper-generated.yml

### anonymized-secrets-compare-repo-uri

* delete-lifecycle-sample-sync-helper-generated.yml

