# Reference dataset

The reference dataset helps understand the features from the COA engine and
serves as a unique source of truth for the tests and the documentation
(although it is still in concurrence with fixtures for spec/scripts/generate-depls)

## Hello World

The first kind of example that is exhibited here is a "hello world". It
contains just over the bare minimum to make the COA works and generate
pipelines.

### Bosh

You can find a Hello World example descbribed in [bosh-sample-hello-world.md](bosh-sample-hello-world.md)

#### TODO
* Add an example to run an errand after the deployment

### Terraform

You can find a Hello World example descbribed in [terraform-sample-hello-world.md](terraform-sample-hello-world.md)

### Cloud Foundry apps

You can find a Hello World example descbribed in [cf-apps-sample-hello-world.md](cf-apps-sample-hello-world.md)

### CredHub
(e.g. credhub + UAA docker image)

### Concourse

You can find a Hello World example descbribed in [concourse-sample-hello-world.md](concourse-sample-hello-world.md)

### Kubernetes

##TODO
reorganize reference dataset according to one of the following structure:

- proposal 1: 

```bash

templates-repository
├── hello-world-root-depl
└── shared-config.yml # optional - if not present, a default is generated

template_repository/hello-world-root-depl
├── hello-world-root-depl-versions.yml
├── bosh-deployment-sample
│   ├── deployment-dependencies.yml
│   └── template
│       ├── adding-ntp-release-operators.yml
│       ├── bosh-deployment-sample-tpl.yml
│       ├── ntp-release-vars.yml
│       ├── openstack
│       │   └── nginx-operators.yml
│       ├── post-deploy.sh
│       └── pre-deploy.sh
├── sample-deployment-to-be-deleted
        ├── deployment-dependencies.yml
        └── template
            ├── index.html
            ├── manifest-tpl.yml
            └── Staticfile
├── sample-deployment-to-be-deleted
│   ├── deployment-dependencies.yml
│   └── template
│       └── to-be-deleted-deployment.yml
└── template
    ├── cloud-config.yml
    ├── deploy.sh
    ├── openstack
    │   └── disk-types-cloud-operators.yml
    └── runtime-config.yml
```

```bash
config-repoitory
├── hello-world-root-depl
├── shared
└── private-config.yml


config_repository/hello-world-root-depl
├── ci-deployment-overview.yml
├── cloud-config.yml  # generated
├── bosh-deployment-sample
│   ├── bosh-deployment-sample.yml # generated
│   ├── enable-deployment.yml
│   └── secrets
│       ├── meta.yml
│       └── secrets.yml
├── cf-apps-deployments #for cf-app, directory should be named like this
│   └── generic-app 
│       ├── enable-cf-app.yml
│       ├── generic-app_manifest.yml  # generated
│       └── secrets
│           ├── meta.yml
│           └── secrets.yml
├── runtime-config.yml # generated
├── secrets
│   ├── meta.yml
│   └── secrets.yml
└── terraform-config
    ├── secrets
    │   ├── meta.yml
    │   └── secrets.yml
    ├── spec
    │   └── my-private-terraform-spec.tf
    └── terraform.tfstate  # generated


shared
├── certs
│   ├── internal_paas-ca
│   │   ├── server-ca.crt
│   │   └── server-ca.key
│   └── custom-public-certs
├── keypair
│   └── bosh.pem
├── meta.yml
└── secrets.yml

```



- proposal 2:
