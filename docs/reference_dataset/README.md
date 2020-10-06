# Reference dataset

The reference dataset helps understand the features from the COA engine and
serves as a unique source of truth for the tests and the documentation
(although it is still in concurrence with fixtures for spec/scripts/generate-depls)

## Hello World

The first kind of example that is exhibited here is a ["hello world"](hello-world-root-depls.md). It
contains just over the bare minimum to make the COA works and generates pipelines. This root deployment is a brunch of deployments based on different technologies. We illustrate usage through two repository samples: [config repository](config_repository/) and [templates repository](template_repository/)

### Bosh

You can find an example of `bosh-deployment-sample` described in  ["hello world"](hello-world-root-depls.md)

#### TODO
* Add an example to run an errand after the deployment

### Terraform

You can find an example of `terraform-config` described in ["hello world"](hello-world-root-depls.md)

### Cloud Foundry apps

You can find an example of `cf-apps-deployments` described in ["hello world"](hello-world-root-depls.md)

### Concourse

You can find an example of `concourse-config` described in ["hello world"](hello-world-root-depls.md)

### Kubernetes

You can find an example of `k8s-config` described in ["hello world"](hello-world-root-depls.md)


## Another World

It contains minimal info to make the COA works and generates **empty** pipelines: ["another hello world"](another-world-root-depls.md). You can start from here and add deployments illustrated by ["hello world"](hello-world-root-depls.md) 
