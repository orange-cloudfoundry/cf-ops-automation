# Directory structure 'another-world-root-depls' for  example

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

### another-world-root-depls overview

```bash
Inactive deployment: config dir for another-world-root-depls does not exist.
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

### another-world-root-depls overview

```bash
another-world-root-depls
├── another-bosh-deployment-sample
│   ├── deployment-dependencies.yml
│   └── template
│       ├── adding-ntp-release-operators.yml
│       ├── another-bosh-deployment-sample-tpl.yml
│       ├── ntp-release-vars.yml
│       ├── openstack
│       │   └── nginx-operators.yml
│       ├── post-deploy.sh
│       └── pre-deploy.sh
├── root-deployment.yml
└── template
    ├── cloud-config-tpl.yml
    ├── deploy.sh
    ├── openstack
    │   └── disk-types-cloud-operators.yml
    └── runtime-config-tpl.yml
```

{:config_repo_name=>"config_repository", :template_repo_name=>"template_repository"}
## List of pipelines in which credentials appear for another-world-root-depls

### bosh-password

* another-world-root-depls-bosh-generated.yml

### bosh-target

* another-world-root-depls-bosh-generated.yml

### bosh-username

* another-world-root-depls-bosh-generated.yml

### cf-ops-automation-branch

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### cf-ops-automation-tag-filter

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### cf-ops-automation-uri

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### credhub-client

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### credhub-secret

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### credhub-server

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### iaas-type

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### paas-templates-branch

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### paas-templates-uri

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### profiles

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### secrets-branch

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### secrets-uri

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### slack-channel

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-bosh-precompile-generated.yml
* another-world-root-depls-k8s-generated.yml

### slack-disable

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### slack-proxy

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### slack-proxy-https-tunnel

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### slack-webhook

* another-world-root-depls-bosh-generated.yml
* another-world-root-depls-k8s-generated.yml

### stemcell-main-name

* another-world-root-depls-bosh-generated.yml

### stemcell-name-prefix

* another-world-root-depls-bosh-generated.yml

## Required pipeline credentials for another-world-root-depls

### another-world-root-depls-bosh-generated.yml

* bosh-password
* bosh-target
* bosh-username
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* credhub-client
* credhub-secret
* credhub-server
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

### another-world-root-depls-bosh-precompile-generated.yml

* slack-channel

### another-world-root-depls-cf-apps-generated.yml

No credentials required

### another-world-root-depls-concourse-generated.yml

No credentials required

### another-world-root-depls-k8s-generated.yml

* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* credhub-client
* credhub-secret
* credhub-server
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

### another-world-root-depls-news-generated.yml

No credentials required

### another-world-root-depls-tf-generated.yml

No credentials required

### another-world-root-depls-update-generated.yml

No credentials required

