# Directory structure 'cf-apps-sample' for 'hello-world' example

## The config repo

```bash
.
├── ci-deployment-overview.yml
└── generic-app
    ├── enable-cf-app.yml
    └── secrets
        ├── meta.yml
        └── secrets.yml

```

## The template repo

```bash
.
├── cf-apps-sample-versions.yml
├── generic-app
│   ├── deployment-dependencies.yml
│   └── template
│       ├── Staticfile
│       ├── index.html
│       └── manifest-tpl.yml
└── template
    └── deploy.sh

```

## The config files

* [ci-deployment-overview.yml](/docs/reference_dataset/config_repository/hello-world/cf-apps-sample/ci-deployment-overview.yml)
* [generic-app](/docs/reference_dataset/config_repository/hello-world/cf-apps-sample/generic-app)
  * [enable-cf-app.yml](/docs/reference_dataset/config_repository/hello-world/cf-apps-sample/generic-app/enable-cf-app.yml)
  * [secrets](/docs/reference_dataset/config_repository/hello-world/cf-apps-sample/generic-app/secrets)
    * [meta.yml](/docs/reference_dataset/config_repository/hello-world/cf-apps-sample/generic-app/secrets/meta.yml)
    * [secrets.yml](/docs/reference_dataset/config_repository/hello-world/cf-apps-sample/generic-app/secrets/secrets.yml)

## The template files

* [cf-apps-sample-versions.yml](/docs/reference_dataset/template_repository/hello-world/cf-apps-sample/cf-apps-sample-versions.yml)
* [generic-app](/docs/reference_dataset/template_repository/hello-world/cf-apps-sample/generic-app)
  * [deployment-dependencies.yml](/docs/reference_dataset/template_repository/hello-world/cf-apps-sample/generic-app/deployment-dependencies.yml)
  * [template](/docs/reference_dataset/template_repository/hello-world/cf-apps-sample/generic-app/template)
    * [index.html](/docs/reference_dataset/template_repository/hello-world/cf-apps-sample/generic-app/template/index.html)
    * [manifest-tpl.yml](/docs/reference_dataset/template_repository/hello-world/cf-apps-sample/generic-app/template/manifest-tpl.yml)
    * [Staticfile](/docs/reference_dataset/template_repository/hello-world/cf-apps-sample/generic-app/template/Staticfile)
* [template](/docs/reference_dataset/template_repository/hello-world/cf-apps-sample/template)
  * [deploy.sh](/docs/reference_dataset/template_repository/hello-world/cf-apps-sample/template/deploy.sh)

## Required pipeline credentials for cf-apps-sample

### cf-apps-sample-cf-apps-generated.yml

* slack-webhook
* secrets-uri
* secrets-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* paas-templates-uri
* paas-templates-branch
* slack-channel
* concourse-cf-apps-sample-target
* concourse-cf-apps-sample-username
* concourse-cf-apps-sample-password

### cf-apps-sample-concourse-generated.yml

No credentials required

### cf-apps-sample-generated.yml

* slack-webhook
* secrets-uri
* secrets-branch
* paas-templates-uri
* paas-templates-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* concourse-cf-apps-sample-target
* concourse-cf-apps-sample-insecure
* concourse-cf-apps-sample-username
* concourse-cf-apps-sample-password
* slack-channel
* bosh-target
* bosh-username
* bosh-password
* iaas-type

### cf-apps-sample-init-generated.yml

* slack-webhook
* concourse-cf-apps-sample-target
* concourse-cf-apps-sample-insecure
* concourse-cf-apps-sample-username
* concourse-cf-apps-sample-password
* secrets-uri
* secrets-branch
* paas-templates-uri
* paas-templates-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel

### cf-apps-sample-news-generated.yml

* stemcell-version

### cf-apps-sample-s3-br-upload-generated.yml

* slack-webhook
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel
* concourse-cf-apps-sample-target
* concourse-cf-apps-sample-username
* concourse-cf-apps-sample-password

### cf-apps-sample-s3-stemcell-upload-generated.yml

* slack-webhook
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel
* concourse-cf-apps-sample-target
* concourse-cf-apps-sample-username
* concourse-cf-apps-sample-password

### cf-apps-sample-sync-helper-generated.yml

* slack-webhook
* anonymized-secrets-repo-uri
* anonymized-secrets-compare-repo-uri
* secrets-uri
* secrets-branch
* cf-ops-automation-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* slack-channel

### cf-apps-sample-tf-generated.yml

No credentials required

