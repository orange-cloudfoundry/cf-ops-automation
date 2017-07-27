#Paas template

#overview
Have a look this plantuml file: [bosh overview](docs/overview.puml). You can generate a graphical view using [etherplant](http://plantuml-etherpad.kermit.rd.francetelecom.fr/)

[Direct link (may not be the latest version)](http://plantuml-etherpad.kermit.rd.francetelecom.fr/png/TP9DJyCm38RFv5TOHKAhjEu7xC1Xi24a418tZbbhjaXj4X9t7_-Un5q_rVNIo7xp-h5ZKbIYW8tnHwYzF22O4xgJmhD0NG1nMkpD1P9tdQCbPNGY7gnqf79bfIReudmZI8KsrFWCSdjZo9EJbbLHSRFzLBapsIlQqYVm-A4EHzgKDOvh914mOsa2qWEV18IlhzN7AgbZ9_jufvAUq76uAznojWGi6IEyEKGzBT1R3QeOw-49y69nN6IEdmsQ1Xgl2ScNzHt6DnPp7a721k4_mMiZDxQ0zbAQke2TgNNXhbrEXfe-ld6E7XOsgwx-hrn2XLKkyoCk0IbVhLRfdPanw3QqEnxO3vQbESyHHoqZRziPzSnTQ33GE4gdAjGaUNFkF5stMf0zDs-_XZ1I9t-DgnPAIf_EQdWhb5QqQFOZHbCXECioVfar752ZauIBmHf57H-YCCnxgWgxa0uKiRkf97ONRCBbpgEdVjc5bFW7)

## Script lifecycle overview
Have a look this plantuml file: [script lifecycle overview](docs/script-lifecycle-overview.puml). You can generate a graphical view using [etherplant](http://plantuml-etherpad.kermit.rd.francetelecom.fr/)

[Direct link (may not be the latest version)](http://plantuml-etherpad.kermit.rd.francetelecom.fr/png/fLIxZjim4AoZhrWudH0fI6l41zmPSPeKYUy30ffQsKGeak33PpN-blkM-x8izR8boxaYBWoG7CtEpYpfXPUOm3EtmdYGeaHUSucWZsYF0byIL0Nu1hJJ9rXimwvUmCSVOd_mtosYIZuOPhtWmZ3bOV5J69H28UnHeMLUsmKmTrarVCIKNEZWs_O9F5P6CeyzzvCCEAOkq4WtgSRBZ1dZ5kDjXIzJeAiLpmue3Te9M2ZX9wAUmyxLZXIHcAv7LEH1JHXt61PhgKEnqQgmTMnnlHbeMF1QXMg7Dac6pY5xQ7jOzcuWcCwjf3cuGbHCKHJEzr2XLGBqKvg-ij6W9N2jA2GFmGcr1sTiu0XVJwVJGvfctiWqpUjAWjVjPhD8tbvlQXdjVDPBogd1SQ5c2Pmfm1FoGDkEZ9IWJISCgBUkkcVkJzv-aAPRqcy5Zn2NfajmYB15LbIOLqK3Ydx5GZUItbwDnIowdSKTNT_AMhulIPHbf-XI878kct-mA94vXBP2HQdEMpEHCQ6oWLHOorJXaZpFuNmM2cZ0c9GepsUWlQjv0EUrwIakTLmmHbEKFZALsbPm7yFZs7scibvK68UW5Fj_mE_vrwRK9Rj3cY8iugm4WhDYvD00fQ-17PcGR1UV2DMWSg5pUAPiDu-_yd6ioMe5gzLr-ryc5sAumNENOZYS87dvt_VZTqzmvwBShHtdabOcKEFawGYstj0v7G3jIC5RLNU9PaPhse4_20UkVPfZJ4mwtML5xrPxtBi5isuFZF4zRnx6J-sBTucKd44kIi7xIjtaZACSfHPvvW8RHtlzvhwFZgfcOSbV)


## Concourse pipeline generation
### deployment pipeline
for each boshrelease, when a enable-deployment.yml is found, it is going to spruce all files in template dir ending with ```-tpl.yml```

if template directory contains scripts with specific name, then these scripts are executed, using the following order :

  1: post-generate.sh: can execute shell operation or spruce task.
     **Restrictions**: as the post-generation script is executed in the same docker image running spruce, no spiff is available.

  2: pre-bosh-deploy.sh: can execute shell operation or spiff task. 

  3: post-bosh-deploy.sh: can execute shell operation (including curl). 

* to generate an additional errand step, insert a key ```errands```, with a subkey named like the errand job to execute 
in deployment-dependencies.yml  

### git submodules
By default, git submodules are not check outed (this can be very time consuming). But some bosh releases require these 
  submodule. There is a mechanism to detect submodule for a release and include it only for this bosh release

#### enable deployment format (enable-deployment.yml)
this is an empty yaml file !

#### deployment dependencies format (deployment-dependencies.yml)

in deployment-dependencies.yml, it is possible: 

    - to add secrets path to trigger the build
        resources:
          secrets:
            extented_scan_path: ["ops-depls/cloudfoundry", "...."]

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

deployment-dependencies.yml sample (should be placed in ths boshrelease deployment dir):

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

### Cloudfoundry application deployment
for each cf-application, when a enable-cf-app.yml is found, it is going to spruce all files in template dir ending with ```-tpl.yml```

if template directory contains pre-cf-push.sh, then this scripts is run:
    - you are already logged in CF,
    - you have to download your binaries before uploading to CF

#### file format

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

if a ci_deployments descriptor (ie a file called ci-deployment-overview.yml) is detected in secrets dir/<depls>, then an
auto-update job is generated.

### terraform

ci-deployment-overview.yml may include a terraform_config key to generate a terraform  pipeline.The terraform_config key
 must include a state_file_path key to indicate tfstate file path. It assumes that a spec dir is also included alongside
 tfstate
  
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

#usage
How to use it :

This repository should be use with a repository containing secrets. A sample secrets repo is available here:
         
```
git clone https://www.forge.orange-labs.fr/plugins/git/clara-cloud/public-sample-secrets.git
```
# anonimyzation

       
# [status](docs/work-in-progress.md)

# FAQ

## How to initialize a new bosh deployment template ?
run ./init-template.sh, and it creates empty placeholder.

## How to enable a bosh deployment template ?

deployment-dependencies.yml sample:

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

### sample

have a look to this [post-generate.sh](micro-depls/terraform-config/template/post-generate.sh)

## How to bootstrap pipelines to a new concourse

simply run [concourse-bootstrap.sh](concourse-bootstrap.sh) with the appropriate environment variable set  


```
SECRETS=<path_to_your_secret_dir> FLY_TARGET=<your_target> ./concourse-bootstrap.sh
```

### pre requisite
The following tools are required to run [concourse-bootstrap.sh](concourse-bootstrap.sh)
 - git 
 - ruby
 - fly, the concourse CLI
    - Login to concourse in main team


## How to create a new root deployment

To setup a new paas-template repo, a new secrets repo or to add a new root deployment, you can run 
[create-root-depls](scripts/create-root-depls.rb) script to create empty files.

### pre requisite
The following tools are required to run [create-root-depls](scripts/create-root-depls.rb)
 - ruby

# Development

## Running the Test Suite

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
