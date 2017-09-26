# cf-ops-automation

This repo contains automation for managing cloudfoundry and services used by Orange CF SKC. 

It provides:
- concourse-based continuous deployment pipeline generator for common resource types: bosh deployments, cf apps, terraform resources
- templating engine supporting operations of multiple environments (e.g. preprod/prod-region1/prod-region2) 

The goal is to automate most (if not all) interactive operations of Bosh, CF API, Iaas APIs, while keeping volume of concourse boilerplate code low, and limit concourse learning prereqs before contributing to automation.

# Overview

This repo takes templates and instances as input, and generates concourse pipelines that automatically reload and execute. As a result, resources gets provisionned and operated:
* Templates are specified in a git repo (referred to as "paas-templates"). It contains a hierarchical structure with root deployment and nested deployment templates.
* Instances are specified in a git repo (referred to as "secrets"). Their structure mimics the template structure, indicating which deployment template should instanciated. See  
* Generated pipeline triggers provisioning of resources whose credentials and secrets are pushed into a git repo (referred to as "secrets"). Plan is to move credentials to credhub.
 
A `root deployment` contains infrastructure to operate `nested deployment`s. 
* A root deployment typically contains Iaas prereqs, Bosh director and its cloud-config, DNS infrastrucure, private git server, Concourse, log collection, monitoring/alerting, credhub, etc... 
* Nested deployments are resources created by a root deployment. This typically include cloudfoundry, admin-ui, services, ... 


## Orange CF-SKC Deployment topology

This repo is maintained by the Orange CF skill center team for its deployments. The team's infrastructure deployment topology and bootstrapping process is illustred below:    
![Overview of pipeline generation for bosh deployments](http://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/orange-cloudfoundry/cf-ops-automation/master/docs/overview.puml?lastRefreshOn=17082017).

Source is in the [plantuml](http://plantuml.com/) file: [bosh overview](docs/overview.puml), see [caching tips](https://stackoverflow.com/questions/32203610/how-to-integrate-uml-diagrams-into-gitlab-or-github)

The `inception`, `micro-depls`, `master-depls`, `ops-depls`, `expe-depls` are `root deployment`s in Orange CF skill center infrastructure.

The nested deployment model enables a split of responsibility as the operations team scales.

The plan is to open source the Orange's CF skill center team template git repo in the future (once the remaining secrets get cleaned up).

## Script lifecycle overview

The diagram below illustrates the concourse pipeline generation for 2 types of supported resources (Bosh deployments and CF apps). The diagram includes the main hooks that templating engine supports during the resources life cycle. 

![script lifecycle overview](http://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/orange-cloudfoundry/cf-ops-automation/master/docs/script-lifecycle-overview.puml?lastRefreshOn=17082017). 


## Concourse pipeline generation

This section details the format supported by the templating engine in both the template repo and the secrets repo. 

### Bosh deployment resources template format

For each boshrelease, when an `enable-deployment.yml` file is found in the secrets repo, it is going to spruce all template files in the corresponding template repo dir (template files need to end with ```-tpl.yml``` extension).

If a template directory contains hook scripts with specific name, then these scripts get executed in the following order :

  1: `post-generate.sh`: can execute shell operation or spruce task.
     **Restrictions**: as the post-generation script is executed in the same docker image running spruce, no spiff is available.
     Environment variables available:

      - GENERATE_DIR: directory holding generated files. It's an absolute path.
      - BASE_TEMPLATE_DIR: directory where `post-generate.sh` is located. It's an relative path. 

  2: `pre-bosh-deploy.sh`: can execute shell operation or spiff task. 
     Environment variables available:
     
      - GENERATE_DIR: directory holding generated files. It's an absolute path. 
      - BASE_TEMPLATE_DIR: directory where `pre-bosh-deploy.sh` is located. It's an relative path. 
      - SECRETS_DIR: directory holding secrets related to current deployment. It's an relative path.

  3: `post-bosh-deploy.sh`: can execute shell operation (including curl).
     Environment variables available:
     
      - GENERATE_DIR: directory holding generated files. It's an absolute path. 
      - BASE_TEMPLATE_DIR: directory where `post-bosh-deploy.sh` is located. It's an relative path.
      - SECRETS_DIR: directory holding secrets related to current deployment. It's an relative path.

* to generate an additional errand step, in a `deployment-dependencies.yml` file, insert a key ```errands``` with a subkey named like the errand job to execute 
  
### Bosh cli v2 specific features support
The newest bosh feature are not implemented in bosh cli v1. So some feature are only available to deployments using bosh cli v2.
 
#### ops-files and vars-files
By convention, all files in template dir matching ```*-operators-tpl.yml``` are processed by spruce and generate ```*-operators.yml``` files.
Then files are used by ```bosh-deployment``` as ```ops-files``` inputs.
The same mechanism is used for ```*-vars-tpl.yml``` with vars-files.

**Migration v1 to v2 tips**: empty vars-files and ops-files are generated to avoid an error message

### git submodules
By default, git submodules are not checked out (this can be very time consuming). But some bosh releases require these 
  submodule. There is a mechanism to detect submodule for a release and include it only for this bosh release

#### enable deployment format (enable-deployment.yml)
this is expected to be an empty yaml file !

#### deployment dependencies format (deployment-dependencies.yml)

In `deployment-dependencies.yml`, it is possible to: 

- add secrets path to trigger the build:

``` yaml
        resources:
          secrets:
            extented_scan_path: ["ops-depls/cloudfoundry", "...."]
```
        
- choose a bosh cli version. By default, bosh cli v2 is used unless v1 specified in cli_version
        
``` yaml
        deployment:
          micro-bosh:
            cli_version: v1
            stemcells:
                ...
            releases:
                ...
```

Following is a `deployment-dependencies.yml` sample (should be placed in the boshrelease deployment dir):

``` yaml

---
deployment:
  micro-bosh:
    stemcells:
      bosh-openstack-kvm-ubuntu-trusty-go_agent:
    releases:
      route-registrar-boshrelease:
        base_location: https://bosh.io/d/github.com/
        repository: cloudfoundry-community/route-registrar-boshrelease    
      shield:
        base_location: https://bosh.io/d/github.com/
        repository: starkandwayne/shield-boshrelease        
      xxx_boshrelease:
        base_location: https://bosh.io/d/github.com/
        repository: xxx/yyyy
    errands:
      smoke_tests:       
```

### Cloudfoundry application resources template format

For each cf-application, when a `enable-cf-app.yml` file is found, it is going to spruce all files in the template dir ending with ```-tpl.yml```

If a template directory contains a `pre-cf-push.sh` file, then this script is run:
    - you are already logged in CF,
    - you have to download your binaries before uploading to CF

Environment variables available:
     
  - GENERATE_DIR: directory holding generated files. It's an absolute path. 
  - BASE_TEMPLATE_DIR: directory where `pre-cf-push.sh` is located. It's an relative path.
  - SECRETS_DIR: directory holding secrets related to current deployment. It's an relative path.


#### `enable-cf-app.yml` file format

``` yaml

---
cf-app:
  probe-apps-domains:
    cf_api_url: 
    cf_username: 
    cf_password: 
    cf_organization: 
    cf_space:
``` 

### pipeline auto-update

If a ci_deployments descriptor (i.e. a file called `ci-deployment-overview.yml`) is detected in secrets dir/<depls>, then an
auto-update job is generated.

### terraform

`ci-deployment-overview.yml` may include a `terraform_config` key to generate a terraform  pipeline.The `terraform_config` key
 must include a `state_file_path` key to indicate tfstate file path. It assumes that a spec dir is also included alongside
 the tfstate file.
  
#### file format

``` yaml

---
ci-deployment:
  ops-depls:
    target_name: concourse-ops
    terraform_config:
      state_file_path: ops-depls/tf-config-dir
    pipelines:
      ops-depls-generated:
        config_file: xxxx/pipelines/ops-depls-generated.yml
        vars_files:
        - xxx/pipelines/credentials-ops-depls-pipeline.yml
        - xxx/ops-depls-versions.yml
      ops-depls-cf-apps-generated:
        config_file: xxx/pipelines/ops-depls-cf-apps-generated.yml
        vars_files:
        - xxx/pipelines/credentials-ops-depls-pipeline.yml
        - xxx/ops-depls-versions.yml
```

### delete lifecycle support

#### bosh deployment
It scans secrets/<root_deployment> for directories. If a ```enable-deployment.yml``` is found, deployment status is set 
to ```enabled```, otherwise to ```disabled```. 
```disabled``` deployment are going to be candidates for deletion. 

#### cf-app deployment
NYI

# Pipelines
## standalone

* [bootstraps-all-init-pipelines](concourse/pipelines/bootstraps-all-init-pipelines.yml): bootstrap all init pipelines 
* [micro-bosh-init-pipeline](concourse/pipelines/micro-bosh-init-pipeline.yml): !!! WIP !!! to manage bosh-micro
* [sync-feature-branches](concourse/pipelines/sync-feature-branches.yml): manage a WIP branch based on develop and any feature branches  
* [sync-hotfix-branches](concourse/pipelines/sync-hotfix-branches.yml): manage a WIP branch based on master and any hotfix branches

## template

* [cf-apps-pipeline](concourse/pipelines/templates/cf-apps-pipeline.yml): to manage cf-app associated to a root-deployment
* [depls-pipeline](concourse/pipelines/templates/depls-pipeline.yml): to manage deployments associated to a root-deployment
* [init-pipeline](concourse/pipelines/templates/init-pipeline.yml): to initialize all pipelines related to a root-deployment
* [news-pipeline](concourse/pipelines/templates/news-pipeline.yml): to be notified on new bosh release version for a root-deployment  
* [sync-helper-pipeline](concourse/pipelines/templates/sync-helper-pipeline.yml): to ease secret repo management


# anonimyzation

       
# Status and roadmap

See ~~~[status](docs/work-in-progress.md)~~~ as well as [github issues](https://github.com/orange-cloudfoundry/cf-ops-automation/issues).

# Credits

This repo was inspired by great work shared in
 * https://github.com/alphagov/paas-cf
 * https://github.com/cloudfoundry/buildpacks-ci/ 

# FAQ

## How to initialize a new bosh deployment template ?
run `./init-template.sh`, and it creates empty placeholder.

## How to enable a bosh deployment template ?

`deployment-dependencies.yml` sample:

``` yaml

---
deployment:
  micro-bosh:
    stemcells:
      bosh-openstack-kvm-ubuntu-trusty-go_agent:
    releases:
      route-registrar-boshrelease:
        base_location: https://bosh.io/d/github.com/
        repository: cloudfoundry-community/route-registrar-boshrelease    
      shield:
        base_location: https://bosh.io/d/github.com/
        repository: starkandwayne/shield-boshrelease        
      xxx_boshrelease:
        base_location: https://bosh.io/d/github.com/
        repository: xxx/yyyy
    errands:
      smoke_tests:        
```

## How to upload a bosh release not available on bosh.io?
use ```deploy.sh``` script like [this](ops-depls/template/deploy.sh) to manually upload release.
```deploy.sh``` use bosh cli v2 syntax.

## How to generate a tfvars in json from a yaml template?
You can use spruce embedded with post-generate.sh to do it !
See [post-generate.sh](micro-depls/terraform-config/template/post-generate.sh) script t

### Sample

There is no yet public template sample. Orange employees can have a look to the [post-generate.sh](micro-depls/terraform-config/template/post-generate.sh) in the private paas-template repo.

## How to bootstrap pipelines to a new concourse

simply run [concourse-bootstrap.sh](scripts/concourse-bootstrap.sh) with the appropriate environment variable set. It loads the
```bootstrap-all-init-pipelines``` pipeline and triggers it.  


```
SECRETS=<path_to_your_secret_dir> FLY_TARGET=<your_target> ./concourse-bootstrap.sh
```

### pre requisite
The following tools are required to run [concourse-bootstrap.sh](scripts/concourse-bootstrap.sh)
 - git 
 - fly, the concourse CLI
    - Login to concourse in main team


## How to create a new root deployment

To setup a new paas-template repo, a new secrets repo or to add a new root deployment, you can run 
[create-root-depls](scripts/create-root-depls.rb) script to create empty files.

### pre requisite
The following tools are required to run [create-root-depls](scripts/create-root-depls.rb)
 - ruby

# Development

Active development happens on `develop` 

## Running the Test Suite

Prereqs:
- install ruby, gems and bundler (version >= 1.15.1):
   - `gem install bundler` 
- install dependent gems: `bundle install --path vendor/bundle`

If you are running the full test suite, some of the integration tests are dependent on the fly CLI.


To login to the Fly CLI and target the cf-ops-automation CI:

```sh
fly -t cf-ops-automation login
```

You will be prompted to select either the Github, UAA or Basic Auth authentication methods.

After these are set up, you will be able to run the test suite via:

```sh
bundler exec rspec
```

## Contributing Code

If you've got a feature you want to see or a bug you'd like to fix, pull requests are the way to go.

### Submitting Pull Requests

 * All pull requests should be made to `develop`. Only Pull Request based on this branch trigger automated build.
