#Paas template

#overview
Have a look this plantuml file: [bosh overview](docs/overview.puml). You can generate a graphical view using [etherplant](http://plantuml-etherpad.kermit.rd.francetelecom.fr/)

[Direct link (may not be the latest version)](http://plantuml-etherpad.kermit.rd.francetelecom.fr/png/TP9DJyCm38RFv5TOHKAhjEu7xC1Xi24a418tZbbhjaXj4X9t7_-Un5q_rVNIo7xp-h5ZKbIYW8tnHwYzF22O4xgJmhD0NG1nMkpD1P9tdQCbPNGY7gnqf79bfIReudmZI8KsrFWCSdjZo9EJbbLHSRFzLBapsIlQqYVm-A4EHzgKDOvh914mOsa2qWEV18IlhzN7AgbZ9_jufvAUq76uAznojWGi6IEyEKGzBT1R3QeOw-49y69nN6IEdmsQ1Xgl2ScNzHt6DnPp7a721k4_mMiZDxQ0zbAQke2TgNNXhbrEXfe-ld6E7XOsgwx-hrn2XLKkyoCk0IbVhLRfdPanw3QqEnxO3vQbESyHHoqZRziPzSnTQ33GE4gdAjGaUNFkF5stMf0zDs-_XZ1I9t-DgnPAIf_EQdWhb5QqQFOZHbCXECioVfar752ZauIBmHf57H-YCCnxgWgxa0uKiRkf97ONRCBbpgEdVjc5bFW7)



## Concourse pipeline generation
### deployment pipeline
for each boshrelease, when a deployment-dependencies.yml is found, it is going to spruce all files in template dir ending with ```-tpl.yml```

if template directory contains scripts with specific name, then these scripts are executed, using the following order :

  1: post-generate.sh: can execute shell operation or spruce task.
     **Restrictions**: as the post-generation script is executed in the same docker image running spruce, no spiff is available.

  2: pre-bosh-deploy.sh: can execute shell operation or spiff task. 

  3: post-bosh-deploy.sh: can execute shell operation (including curl). 

* to generate an additional errand step, insert a key ```errands```, with a subkey named like the errand job to execute 
in deployment-dependencies.yml  

TODO: add info about gitsubmodule detection

#### deployment dependencies format

in deployment-dependencies.yml, it is possible to add secrets path to trigger the build
    resources:
      secrets:
        extented_scan_path: ["ops-depls/cloudfoundry", "...."]


deployment-dependencies.yml sample (should be placed in secrets repo):

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
       
#status
 - Pipeline generation
    - [ ] auto-init
    - [X] deployments except micro-bosh 
        - handle cloud-config & runtime-config
    - [X] terraform
    - [X] cf-apps

 - Enhancements
    - Pipelines
        - [ ] flow control to avoid Concourse out of resource crash. Workaround: increase number of workers. 
        - cf-apps
            - [ ] use concourse resource to push instead of shell
            - [ ] use dedicated resource to handle binary download (ie maven, github-release, etc...)
    - concourse credentials generation from template (like manifest)            
            

 - TODO     
    - Pipeline generation
        - deployments
            - [ ] cloud-config should extract net_id from terraform
                tfstate => yaml. (network tf =>  net-id => cloud-config-tpl.yml. (( grab tf-exchange.id )) )
            - [ ] generate check-resource script
            - [ ] better support of bosh release not available on bosh.io
        - cf-apps
            - [ ] support/test multi app deployment. 
    - [ ] enable auto-init for manual pipeline
    - migrate manual pipeline to generated pipeline
        - [ ] auto-init
        - [ ] terraform
    - [ ] add tests to validate pipeline generation
    - mattermost:
        - check message

 