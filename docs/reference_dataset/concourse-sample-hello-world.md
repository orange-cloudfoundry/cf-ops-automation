# Directory structure 'concourse-sample' for 'hello-world' example

## The config repo

```bash
.
├── ci-deployment-overview.yml
└── pipeline-sample
    ├── enable-deployment.yml
    └── secrets
        ├── meta.yml
        └── secrets.yml
```

## The template repo

```bash
.
├── concourse-sample-versions.yml
├── pipeline-sample
│   ├── concourse-pipeline-config
│   │   └── pipeline-sample.yml
│   └── deployment-dependencies.yml
└── template
    ├── cloud-config-tpl.yml
    ├── deploy.sh
    └── runtime-config-tpl.yml
```

## The config files

* [ci-deployment-overview.yml](/docs/reference_dataset/config_repository/hello-world/concourse-sample/ci-deployment-overview.yml)
* [pipeline-sample](/docs/reference_dataset/config_repository/hello-world/concourse-sample/pipeline-sample)
  * [enable-deployment.yml](/docs/reference_dataset/config_repository/hello-world/concourse-sample/pipeline-sample/enable-deployment.yml)
  * [secrets](/docs/reference_dataset/config_repository/hello-world/concourse-sample/pipeline-sample/secrets)
    * [meta.yml](/docs/reference_dataset/config_repository/hello-world/concourse-sample/pipeline-sample/secrets/meta.yml)
    * [secrets.yml](/docs/reference_dataset/config_repository/hello-world/concourse-sample/pipeline-sample/secrets/secrets.yml)

## The template files

* [concourse-sample-versions.yml](/docs/reference_dataset/template_repository/hello-world/concourse-sample/concourse-sample-versions.yml)
* [pipeline-sample](/docs/reference_dataset/template_repository/hello-world/concourse-sample/pipeline-sample)
  * [concourse-pipeline-config](/docs/reference_dataset/template_repository/hello-world/concourse-sample/pipeline-sample/concourse-pipeline-config)
    * [pipeline-sample.yml](/docs/reference_dataset/template_repository/hello-world/concourse-sample/pipeline-sample/concourse-pipeline-config/pipeline-sample.yml)
  * [deployment-dependencies.yml](/docs/reference_dataset/template_repository/hello-world/concourse-sample/pipeline-sample/deployment-dependencies.yml)
* [template](/docs/reference_dataset/template_repository/hello-world/concourse-sample/template)
  * [cloud-config-tpl.yml](/docs/reference_dataset/template_repository/hello-world/concourse-sample/template/cloud-config-tpl.yml)
  * [deploy.sh](/docs/reference_dataset/template_repository/hello-world/concourse-sample/template/deploy.sh)
  * [runtime-config-tpl.yml](/docs/reference_dataset/template_repository/hello-world/concourse-sample/template/runtime-config-tpl.yml)

## Required pipeline credentials for concourse-sample

### concourse-sample-cf-apps-generated.yml

No credentials required

### concourse-sample-concourse-generated.yml

* slack-webhook
* concourse-concourse-sample-target
* concourse-concourse-sample-insecure
* concourse-concourse-sample-username
* concourse-concourse-sample-password
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* secrets-uri
* secrets-branch
* paas-templates-uri
* paas-templates-branch
* slack-channel
* iaas-type

### concourse-sample-generated.yml

* slack-webhook
* secrets-uri
* secrets-branch
* paas-templates-uri
* paas-templates-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* concourse-concourse-sample-target
* concourse-concourse-sample-insecure
* concourse-concourse-sample-username
* concourse-concourse-sample-password
* slack-channel
* bosh-target
* bosh-username
* bosh-password
* iaas-type

### concourse-sample-init-generated.yml

* slack-webhook
* concourse-concourse-sample-target
* concourse-concourse-sample-insecure
* concourse-concourse-sample-username
* concourse-concourse-sample-password
* secrets-uri
* secrets-branch
* paas-templates-uri
* paas-templates-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel

### concourse-sample-news-generated.yml

* stemcell-name
* stemcell-version

### concourse-sample-s3-br-upload-generated.yml

* slack-webhook
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel
* concourse-concourse-sample-target
* concourse-concourse-sample-username
* concourse-concourse-sample-password

### concourse-sample-s3-stemcell-upload-generated.yml

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
* concourse-concourse-sample-target
* concourse-concourse-sample-username
* concourse-concourse-sample-password

### concourse-sample-sync-helper-generated.yml

* slack-webhook
* anonymized-secrets-repo-uri
* anonymized-secrets-compare-repo-uri
* secrets-uri
* secrets-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel

### concourse-sample-tf-generated.yml

No credentials required

## List of pipelines in which credentials appear for concourse-sample

### slack-webhook

* concourse-sample-concourse-generated.yml
* concourse-sample-generated.yml
* concourse-sample-init-generated.yml
* concourse-sample-s3-br-upload-generated.yml
* concourse-sample-s3-stemcell-upload-generated.yml
* concourse-sample-sync-helper-generated.yml

### concourse-concourse-sample-target

* concourse-sample-concourse-generated.yml
* concourse-sample-generated.yml
* concourse-sample-init-generated.yml
* concourse-sample-s3-br-upload-generated.yml
* concourse-sample-s3-stemcell-upload-generated.yml

### concourse-concourse-sample-insecure

* concourse-sample-concourse-generated.yml
* concourse-sample-generated.yml
* concourse-sample-init-generated.yml

### concourse-concourse-sample-username

* concourse-sample-concourse-generated.yml
* concourse-sample-generated.yml
* concourse-sample-init-generated.yml
* concourse-sample-s3-br-upload-generated.yml
* concourse-sample-s3-stemcell-upload-generated.yml

### concourse-concourse-sample-password

* concourse-sample-concourse-generated.yml
* concourse-sample-generated.yml
* concourse-sample-init-generated.yml
* concourse-sample-s3-br-upload-generated.yml
* concourse-sample-s3-stemcell-upload-generated.yml

### cf-ops-automation-uri

* concourse-sample-concourse-generated.yml
* concourse-sample-generated.yml
* concourse-sample-init-generated.yml
* concourse-sample-s3-br-upload-generated.yml
* concourse-sample-s3-stemcell-upload-generated.yml
* concourse-sample-sync-helper-generated.yml

### cf-ops-automation-branch

* concourse-sample-concourse-generated.yml
* concourse-sample-generated.yml
* concourse-sample-init-generated.yml
* concourse-sample-s3-br-upload-generated.yml
* concourse-sample-s3-stemcell-upload-generated.yml
* concourse-sample-sync-helper-generated.yml

### cf-ops-automation-tag-filter

* concourse-sample-concourse-generated.yml
* concourse-sample-generated.yml
* concourse-sample-init-generated.yml
* concourse-sample-s3-br-upload-generated.yml
* concourse-sample-s3-stemcell-upload-generated.yml
* concourse-sample-sync-helper-generated.yml

### secrets-uri

* concourse-sample-concourse-generated.yml
* concourse-sample-generated.yml
* concourse-sample-init-generated.yml
* concourse-sample-sync-helper-generated.yml

### secrets-branch

* concourse-sample-concourse-generated.yml
* concourse-sample-generated.yml
* concourse-sample-init-generated.yml
* concourse-sample-sync-helper-generated.yml

### paas-templates-uri

* concourse-sample-concourse-generated.yml
* concourse-sample-generated.yml
* concourse-sample-init-generated.yml

### paas-templates-branch

* concourse-sample-concourse-generated.yml
* concourse-sample-generated.yml
* concourse-sample-init-generated.yml

### slack-channel

* concourse-sample-concourse-generated.yml
* concourse-sample-generated.yml
* concourse-sample-init-generated.yml
* concourse-sample-s3-br-upload-generated.yml
* concourse-sample-s3-stemcell-upload-generated.yml
* concourse-sample-sync-helper-generated.yml

### iaas-type

* concourse-sample-concourse-generated.yml
* concourse-sample-generated.yml

### bosh-target

* concourse-sample-generated.yml

### bosh-username

* concourse-sample-generated.yml

### bosh-password

* concourse-sample-generated.yml

### stemcell-name

* concourse-sample-news-generated.yml

### stemcell-version

* concourse-sample-news-generated.yml
* concourse-sample-s3-stemcell-upload-generated.yml

### s3-stemcell-bucket

* concourse-sample-s3-stemcell-upload-generated.yml

### s3-stemcell-region-name

* concourse-sample-s3-stemcell-upload-generated.yml

### s3-stemcell-access-key-id

* concourse-sample-s3-stemcell-upload-generated.yml

### s3-stemcell-secret-key

* concourse-sample-s3-stemcell-upload-generated.yml

### s3-stemcell-endpoint

* concourse-sample-s3-stemcell-upload-generated.yml

### s3-stemcell-skip-ssl-verification

* concourse-sample-s3-stemcell-upload-generated.yml

### anonymized-secrets-repo-uri

* concourse-sample-sync-helper-generated.yml

### anonymized-secrets-compare-repo-uri

* concourse-sample-sync-helper-generated.yml

