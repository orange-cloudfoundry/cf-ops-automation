# Directory structure 'hello-world-root-depls' for  example

## The config repo

### root level overview

```bash
.
├── coa
├── concourse
├── hello-world-root-depls
├── private-config.yml
└── shared
```

### hello-world-root-depls overview

```bash
hello-world-root-depls
├── bosh-deployment-sample
│   ├── enable-deployment.yml
│   ├── protect-deployment.yml
│   └── secrets
│       ├── meta-sample.yml
│       └── secrets.yml
├── cf-apps-deployments
│   └── generic-app
│       ├── Readme.md
│       ├── enable-cf-app.yml
│       ├── secrets
│       │   └── secrets.yml
│       └── spruce-file-sample-from-secrets.txt
├── ci-deployment-overview.yml
├── cloud-config.yml
├── coa-ci-concourse
│   └── protect-deployment.yml
├── delete-sample-for-bosh-only
│   └── secrets
│       └── secrets.yml
├── delete-sample-for-directory
│   └── delete-sample-for-directory.yml
├── git-server
│   └── protect-deployment.yml
├── k8s-sample
│   └── enable-deployment.yml
├── pipeline-sample
│   ├── Readme.md
│   ├── concourse-pipeline-config
│   │   └── virtualbox
│   ├── enable-deployment.yml
│   └── secrets
│       └── secrets.yml
├── runtime-config.yml
├── secrets
│   ├── meta.yml
│   ├── private-config-operators.yml
│   ├── private-runtime-operators.yml
│   └── secrets.yml
├── terraform-config
│   ├── secrets
│   │   └── secrets.yml
│   └── spec
│       └── my-private-terraform-spec.tf
└── terraform-sample
    ├── secrets
    │   ├── meta.yml
    │   └── secrets.yml
    └── spec
        └── my-private-terraform-spec.tf
```

## The template repo

### root level overview

```bash
.
├── another-world-root-depls
├── hello-world-root-depls
├── meta-inf.yml
├── shared-config.yml
└── shared-files
```

### hello-world-root-depls overview

```bash
hello-world-root-depls
├── bosh-deployment-sample
│   ├── deployment-dependencies-openstack.yml
│   ├── deployment-dependencies-vault-profile.yml
│   ├── deployment-dependencies-vsphere.yml
│   ├── deployment-dependencies.yml
│   └── template
│       ├── adding-cron-release-operators.yml
│       ├── bosh-deployment-sample-tpl.yml
│       ├── check-available-clis-during-deploy.sh
│       ├── cron-release-vars.yml
│       ├── openstack
│       │   └── cron-job-configuration-operators.yml
│       ├── post-deploy.sh
│       ├── pre-deploy.sh
│       ├── releases-operators.yml -> ../../../shared-files/releases-operators.yml
│       ├── update-operators.yml -> ../../../shared-files/cf-ops-automation-reference-dataset-submodule-sample/update-operators.yml
│       ├── vault-profile
│       │   ├── adding-vault-release-operators.yml
│       │   └── vault-release-vars.yml
│       └── vsphere
│           └── cron-job-configuration-operators.yml
├── cf-apps-deployments
│   └── generic-app
│       ├── deployment-dependencies.yml
│       └── template
│           ├── cf-env.sh
│           ├── generic-app_manifest-tpl.yml
│           ├── post-deploy.sh
│           ├── pre-cf-push.sh
│           ├── spruce-file-sample-from-templates.txt
│           └── static-app
│               ├── Staticfile
│               └── index.html
├── hooks
│   └── k8s
│       └── deploy.sh
├── k8s-sample
│   └── k8s-config
│       ├── 00-check-coa-provided-artifacts.sh
│       ├── 01-interpolate.sh
│       ├── 02-deploy.sh
│       ├── config.yml
│       ├── openstack
│       │   └── values-iaas-type.yml
│       ├── post-deploy.sh
│       ├── pre-deploy.sh
│       ├── values.yml
│       ├── vault-profile
│       │   ├── custom-dir
│       │   │   └── vault-config.yml
│       │   └── values-profile.yml
│       └── vsphere
│           └── values-iaas-type.yml
├── pipeline-sample
│   ├── concourse-pipeline-config
│   │   ├── docker-image-vars.yml
│   │   └── pipeline-sample-tpl.yml
│   └── deployment-dependencies.yml
├── root-deployment.yml
├── template
│   ├── cloud-config.yml
│   ├── deploy.sh
│   ├── openstack
│   │   └── disk-types-cloud-operators.yml
│   ├── public-config-operators.yml
│   ├── public-runtime-operators.yml
│   └── runtime-config.yml
└── terraform-config
    ├── spec
    │   └── local-provider-sample.tf
    └── template
        ├── post-generate.sh
        └── terraform-tpl.tfvars.yml
```

{config_repo_name: "config_repository", template_repo_name: "template_repository"}
## List of pipelines in which credentials appear for hello-world-root-depls

### background-image-url

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### bosh-password

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml

### bosh-target

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml

### bosh-username

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml

### bot-github-access-token

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml

### cf-ops-automation-branch

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### cf-ops-automation-tag-filter

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### cf-ops-automation-uri

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### concourse-hello-world-root-depls-password

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### concourse-hello-world-root-depls-target

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### concourse-hello-world-root-depls-username

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### credhub-client

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-k8s-generated.yml

### credhub-secret

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-k8s-generated.yml

### credhub-server

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-k8s-generated.yml

### docker-registry-url

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### iaas-type

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-k8s-generated.yml

### k8s-configs-repository-branch

* hello-world-root-depls-k8s-generated.yml

### k8s-configs-repository-password

* hello-world-root-depls-k8s-generated.yml

### k8s-configs-repository-uri

* hello-world-root-depls-k8s-generated.yml

### k8s-configs-repository-username

* hello-world-root-depls-k8s-generated.yml

### paas-templates-branch

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### paas-templates-precompile-branch

* hello-world-root-depls-bosh-precompile-generated.yml

### paas-templates-uri

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### profiles

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### secrets-branch

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### secrets-uri

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### slack-channel

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### slack-disable

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### slack-proxy

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### slack-proxy-https-tunnel

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### slack-webhook

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml
* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-k8s-generated.yml

### stemcell-main-name

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml

### stemcell-name-prefix

* hello-world-root-depls-bosh-generated.yml
* hello-world-root-depls-bosh-precompile-generated.yml

## Required pipeline credentials for hello-world-root-depls

### hello-world-root-depls-bosh-generated.yml

* background-image-url
* bosh-password
* bosh-target
* bosh-username
* bot-github-access-token
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* concourse-hello-world-root-depls-password
* concourse-hello-world-root-depls-target
* concourse-hello-world-root-depls-username
* credhub-client
* credhub-secret
* credhub-server
* docker-registry-url
* iaas-type
* paas-templates-branch
* paas-templates-uri
* profiles
* secrets-branch
* secrets-uri
* slack-channel
* slack-disable
* slack-proxy
* slack-proxy-https-tunnel
* slack-webhook
* stemcell-main-name
* stemcell-name-prefix

### hello-world-root-depls-bosh-precompile-generated.yml

* background-image-url
* bosh-password
* bosh-target
* bosh-username
* bot-github-access-token
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* concourse-hello-world-root-depls-password
* concourse-hello-world-root-depls-target
* concourse-hello-world-root-depls-username
* docker-registry-url
* paas-templates-precompile-branch
* paas-templates-uri
* secrets-branch
* secrets-uri
* slack-channel
* slack-disable
* slack-proxy
* slack-proxy-https-tunnel
* slack-webhook
* stemcell-main-name
* stemcell-name-prefix

### hello-world-root-depls-cf-apps-generated.yml

* background-image-url
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* concourse-hello-world-root-depls-password
* concourse-hello-world-root-depls-target
* concourse-hello-world-root-depls-username
* docker-registry-url
* paas-templates-branch
* paas-templates-uri
* profiles
* secrets-branch
* secrets-uri
* slack-channel
* slack-disable
* slack-proxy
* slack-proxy-https-tunnel
* slack-webhook

### hello-world-root-depls-k8s-generated.yml

* background-image-url
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* concourse-hello-world-root-depls-password
* concourse-hello-world-root-depls-target
* concourse-hello-world-root-depls-username
* credhub-client
* credhub-secret
* credhub-server
* docker-registry-url
* iaas-type
* k8s-configs-repository-branch
* k8s-configs-repository-password
* k8s-configs-repository-uri
* k8s-configs-repository-username
* paas-templates-branch
* paas-templates-uri
* profiles
* secrets-branch
* secrets-uri
* slack-channel
* slack-disable
* slack-proxy
* slack-proxy-https-tunnel
* slack-webhook

