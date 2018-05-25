# Directory structure 'bosh-sample' for 'hello-world' example

## The config repo

```bash
.
├── ci-deployment-overview.yml
└── nginx
    ├── enable-deployment.yml
    └── secrets
        ├── meta.yml
        └── secrets.yml

```

## The template repo

```bash
.
├── bosh-sample-versions.yml
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
    ├── cloud-config.yml
    ├── deploy.sh
    ├── openstack
    │   └── disk-types-cloud-operators.yml
    └── runtime-config.yml

```

## The config files

* [ci-deployment-overview.yml](/docs/reference_dataset/config_repository/hello-world/bosh-sample/ci-deployment-overview.yml)
* [nginx](/docs/reference_dataset/config_repository/hello-world/bosh-sample/nginx)
  * [enable-deployment.yml](/docs/reference_dataset/config_repository/hello-world/bosh-sample/nginx/enable-deployment.yml)
  * [secrets](/docs/reference_dataset/config_repository/hello-world/bosh-sample/nginx/secrets)
    * [meta.yml](/docs/reference_dataset/config_repository/hello-world/bosh-sample/nginx/secrets/meta.yml)
    * [secrets.yml](/docs/reference_dataset/config_repository/hello-world/bosh-sample/nginx/secrets/secrets.yml)

## The template files

* [bosh-sample-versions.yml](/docs/reference_dataset/template_repository/hello-world/bosh-sample/bosh-sample-versions.yml)
* [nginx](/docs/reference_dataset/template_repository/hello-world/bosh-sample/nginx)
  * [deployment-dependencies.yml](/docs/reference_dataset/template_repository/hello-world/bosh-sample/nginx/deployment-dependencies.yml)
  * [template](/docs/reference_dataset/template_repository/hello-world/bosh-sample/nginx/template)
    * [adding-ntp-release-operators.yml](/docs/reference_dataset/template_repository/hello-world/bosh-sample/nginx/template/adding-ntp-release-operators.yml)
    * [nginx-tpl.yml](/docs/reference_dataset/template_repository/hello-world/bosh-sample/nginx/template/nginx-tpl.yml)
    * [ntp-release-vars.yml](/docs/reference_dataset/template_repository/hello-world/bosh-sample/nginx/template/ntp-release-vars.yml)
    * [openstack](/docs/reference_dataset/template_repository/hello-world/bosh-sample/nginx/template/openstack)
      * [nginx-operators.yml](/docs/reference_dataset/template_repository/hello-world/bosh-sample/nginx/template/openstack/nginx-operators.yml)
    * [post-deploy.sh](/docs/reference_dataset/template_repository/hello-world/bosh-sample/nginx/template/post-deploy.sh)
    * [pre-deploy.sh](/docs/reference_dataset/template_repository/hello-world/bosh-sample/nginx/template/pre-deploy.sh)
* [template](/docs/reference_dataset/template_repository/hello-world/bosh-sample/template)
  * [cloud-config.yml](/docs/reference_dataset/template_repository/hello-world/bosh-sample/template/cloud-config.yml)
  * [deploy.sh](/docs/reference_dataset/template_repository/hello-world/bosh-sample/template/deploy.sh)
  * [openstack](/docs/reference_dataset/template_repository/hello-world/bosh-sample/template/openstack)
    * [disk-types-cloud-operators.yml](/docs/reference_dataset/template_repository/hello-world/bosh-sample/template/openstack/disk-types-cloud-operators.yml)
  * [runtime-config.yml](/docs/reference_dataset/template_repository/hello-world/bosh-sample/template/runtime-config.yml)

## Required pipeline credentials for bosh-sample

### bosh-sample-cf-apps-generated.yml

No credentials required

### bosh-sample-concourse-generated.yml

No credentials required

### bosh-sample-generated.yml

* slack-webhook
* secrets-uri
* secrets-branch
* paas-templates-uri
* paas-templates-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* stemcell-name
* s3-stemcell-bucket
* s3-stemcell-region-name
* stemcell-name-prefix
* stemcell-main-name
* s3-stemcell-access-key-id
* s3-stemcell-secret-key
* s3-stemcell-endpoint
* s3-stemcell-skip-ssl-verification
* bosh-target
* bosh-username
* bosh-password
* concourse-bosh-sample-target
* concourse-bosh-sample-insecure
* concourse-bosh-sample-username
* concourse-bosh-sample-password
* slack-channel
* iaas-type
* stemcell-version
* nginx-version
* ntp-version

### bosh-sample-init-generated.yml

* slack-webhook
* concourse-bosh-sample-target
* concourse-bosh-sample-insecure
* concourse-bosh-sample-username
* concourse-bosh-sample-password
* secrets-uri
* secrets-branch
* paas-templates-uri
* paas-templates-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel

### bosh-sample-news-generated.yml

* stemcell-name
* slack-webhook
* secrets-uri
* paas-templates-uri
* paas-templates-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* stemcell-version
* slack-channel
* nginx-version
* ntp-version

### bosh-sample-s3-br-upload-generated.yml

* slack-webhook
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* s3-br-bucket
* s3-br-region-name
* s3-br-access-key-id
* s3-br-secret-key
* s3-br-endpoint
* s3-br-skip-ssl-verification
* slack-channel
* nginx-version
* ntp-version
* concourse-bosh-sample-target
* concourse-bosh-sample-username
* concourse-bosh-sample-password

### bosh-sample-s3-stemcell-upload-generated.yml

* slack-webhook
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* s3-stemcell-bucket
* s3-stemcell-region-name
* s3-stemcell-access-key-id
* s3-stemcell-secret-key
* s3-stemcell-endpoint
* s3-stemcell-skip-ssl-verification
* slack-channel
* stemcell-version
* concourse-bosh-sample-target
* concourse-bosh-sample-username
* concourse-bosh-sample-password

### bosh-sample-sync-helper-generated.yml

* slack-webhook
* anonymized-secrets-repo-uri
* anonymized-secrets-compare-repo-uri
* secrets-uri
* secrets-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel

### bosh-sample-tf-generated.yml

No credentials required

