# Directory structure 'terraform-sample' for 'hello-world' example

## The config repo

```bash
.
├── ci-deployment-overview.yml
└── tf-sample
    ├── enable-deployment.yml
    └── secrets
        ├── meta.yml
        └── secrets.yml
```

## The template repo

```bash
.
├── terraform-sample-versions.yml
└── tf-sample
    └── terraform-config
        ├── spec
        │   └── private-dns.tf
        └── template
            ├── post-generate.sh
            └── terraform-tpl.tfvars.yml
```

## The config files

* [ci-deployment-overview.yml](/docs/reference_dataset/config_repository/hello-world/terraform-sample/ci-deployment-overview.yml)
* [tf-sample](/docs/reference_dataset/config_repository/hello-world/terraform-sample/tf-sample)
  * [enable-deployment.yml](/docs/reference_dataset/config_repository/hello-world/terraform-sample/tf-sample/enable-deployment.yml)
  * [secrets](/docs/reference_dataset/config_repository/hello-world/terraform-sample/tf-sample/secrets)
    * [meta.yml](/docs/reference_dataset/config_repository/hello-world/terraform-sample/tf-sample/secrets/meta.yml)
    * [secrets.yml](/docs/reference_dataset/config_repository/hello-world/terraform-sample/tf-sample/secrets/secrets.yml)

## The template files

* [terraform-sample-versions.yml](/docs/reference_dataset/template_repository/hello-world/terraform-sample/terraform-sample-versions.yml)
* [tf-sample](/docs/reference_dataset/template_repository/hello-world/terraform-sample/tf-sample)
  * [terraform-config](/docs/reference_dataset/template_repository/hello-world/terraform-sample/tf-sample/terraform-config)
    * [spec](/docs/reference_dataset/template_repository/hello-world/terraform-sample/tf-sample/terraform-config/spec)
      * [private-dns.tf](/docs/reference_dataset/template_repository/hello-world/terraform-sample/tf-sample/terraform-config/spec/private-dns.tf)
    * [template](/docs/reference_dataset/template_repository/hello-world/terraform-sample/tf-sample/terraform-config/template)
      * [post-generate.sh](/docs/reference_dataset/template_repository/hello-world/terraform-sample/tf-sample/terraform-config/template/post-generate.sh)
      * [terraform-tpl.tfvars.yml](/docs/reference_dataset/template_repository/hello-world/terraform-sample/tf-sample/terraform-config/template/terraform-tpl.tfvars.yml)

## Required pipeline credentials for terraform-sample

### terraform-sample-cf-apps-generated.yml

No credentials required

### terraform-sample-concourse-generated.yml

No credentials required

### terraform-sample-generated.yml

* slack-webhook
* secrets-uri
* secrets-branch
* paas-templates-uri
* paas-templates-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* concourse-terraform-sample-target
* concourse-terraform-sample-insecure
* concourse-terraform-sample-username
* concourse-terraform-sample-password
* slack-channel
* bosh-target
* bosh-username
* bosh-password
* iaas-type

### terraform-sample-init-generated.yml

* slack-webhook
* concourse-terraform-sample-target
* concourse-terraform-sample-insecure
* concourse-terraform-sample-username
* concourse-terraform-sample-password
* secrets-uri
* secrets-branch
* paas-templates-uri
* paas-templates-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel

### terraform-sample-news-generated.yml

* stemcell-name
* stemcell-version

### terraform-sample-s3-br-upload-generated.yml

* slack-webhook
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel
* concourse-terraform-sample-target
* concourse-terraform-sample-username
* concourse-terraform-sample-password

### terraform-sample-s3-stemcell-upload-generated.yml

* slack-webhook
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel
* concourse-terraform-sample-target
* concourse-terraform-sample-username
* concourse-terraform-sample-password

### terraform-sample-sync-helper-generated.yml

* slack-webhook
* anonymized-secrets-repo-uri
* anonymized-secrets-compare-repo-uri
* secrets-uri
* secrets-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel

### terraform-sample-tf-generated.yml

No credentials required

## List of pipelines in which credentials appear for terraform-sample

### slack-webhook

* terraform-sample-generated.yml
* terraform-sample-init-generated.yml
* terraform-sample-s3-br-upload-generated.yml
* terraform-sample-s3-stemcell-upload-generated.yml
* terraform-sample-sync-helper-generated.yml

### secrets-uri

* terraform-sample-generated.yml
* terraform-sample-init-generated.yml
* terraform-sample-sync-helper-generated.yml

### secrets-branch

* terraform-sample-generated.yml
* terraform-sample-init-generated.yml
* terraform-sample-sync-helper-generated.yml

### paas-templates-uri

* terraform-sample-generated.yml
* terraform-sample-init-generated.yml

### paas-templates-branch

* terraform-sample-generated.yml
* terraform-sample-init-generated.yml

### cf-ops-automation-uri

* terraform-sample-generated.yml
* terraform-sample-init-generated.yml
* terraform-sample-s3-br-upload-generated.yml
* terraform-sample-s3-stemcell-upload-generated.yml
* terraform-sample-sync-helper-generated.yml

### cf-ops-automation-branch

* terraform-sample-generated.yml
* terraform-sample-init-generated.yml
* terraform-sample-s3-br-upload-generated.yml
* terraform-sample-s3-stemcell-upload-generated.yml
* terraform-sample-sync-helper-generated.yml

### cf-ops-automation-tag-filter

* terraform-sample-generated.yml
* terraform-sample-init-generated.yml
* terraform-sample-s3-br-upload-generated.yml
* terraform-sample-s3-stemcell-upload-generated.yml
* terraform-sample-sync-helper-generated.yml

### concourse-terraform-sample-target

* terraform-sample-generated.yml
* terraform-sample-init-generated.yml
* terraform-sample-s3-br-upload-generated.yml
* terraform-sample-s3-stemcell-upload-generated.yml

### concourse-terraform-sample-insecure

* terraform-sample-generated.yml
* terraform-sample-init-generated.yml

### concourse-terraform-sample-username

* terraform-sample-generated.yml
* terraform-sample-init-generated.yml
* terraform-sample-s3-br-upload-generated.yml
* terraform-sample-s3-stemcell-upload-generated.yml

### concourse-terraform-sample-password

* terraform-sample-generated.yml
* terraform-sample-init-generated.yml
* terraform-sample-s3-br-upload-generated.yml
* terraform-sample-s3-stemcell-upload-generated.yml

### slack-channel

* terraform-sample-generated.yml
* terraform-sample-init-generated.yml
* terraform-sample-s3-br-upload-generated.yml
* terraform-sample-s3-stemcell-upload-generated.yml
* terraform-sample-sync-helper-generated.yml

### bosh-target

* terraform-sample-generated.yml

### bosh-username

* terraform-sample-generated.yml

### bosh-password

* terraform-sample-generated.yml

### iaas-type

* terraform-sample-generated.yml

### stemcell-name

* terraform-sample-news-generated.yml

### stemcell-version

* terraform-sample-news-generated.yml

### anonymized-secrets-repo-uri

* terraform-sample-sync-helper-generated.yml

### anonymized-secrets-compare-repo-uri

* terraform-sample-sync-helper-generated.yml

