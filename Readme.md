#Paas template

#overview
Have a look this plantuml file: [bosh overview](docs/overview.puml). You can generate a graphical view using [etherplant](http://plantuml-etherpad.kermit.rd.francetelecom.fr/)

[Direct link (may not be the latest version)](http://plantuml-etherpad.kermit.rd.francetelecom.fr/png/TP9DJyCm38RFv5TOHKAhjEu7xC1Xi24a418tZbbhjaXj4X9t7_-Un5q_rVNIo7xp-h5ZKbIYW8tnHwYzF22O4xgJmhD0NG1nMkpD1P9tdQCbPNGY7gnqf79bfIReudmZI8KsrFWCSdjZo9EJbbLHSRFzLBapsIlQqYVm-A4EHzgKDOvh914mOsa2qWEV18IlhzN7AgbZ9_jufvAUq76uAznojWGi6IEyEKGzBT1R3QeOw-49y69nN6IEdmsQ1Xgl2ScNzHt6DnPp7a721k4_mMiZDxQ0zbAQke2TgNNXhbrEXfe-ld6E7XOsgwx-hrn2XLKkyoCk0IbVhLRfdPanw3QqEnxO3vQbESyHHoqZRziPzSnTQ33GE4gdAjGaUNFkF5stMf0zDs-_XZ1I9t-DgnPAIf_EQdWhb5QqQFOZHbCXECioVfar752ZauIBmHf57H-YCCnxgWgxa0uKiRkf97ONRCBbpgEdVjc5bFW7)



## Concourse pipeline generation
### deployment pipeline
for each boshrelease, when a deployment-dependencies.yml is found, it is going to spruce all files in template dir ending with ```-tpl.yml```

if template directory contains either post-generate.sh or pre-bosh-deploy.sh, then scripts are executed
  - post-generate can execute shell operation or spruce task
  - pre-bosh-deploy can execute shell operation or spiff task

Restrictions: as the post-generation script is executed in the same docker image running spruce, no spiff is available.

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
    - [ ] terraform
    - [X] cf-apps

 - Enhancements
    - Pipelines
        - [ ] flow control to avoid Concourse out of resource crash
        - cf-apps
            - [ ] use concourse resource to push instead of shell
            - [ ] use dedicated resource to handle binary download (ie maven, github-release, etc...)
    - concourse credentials generation from template (like manifest)            
            

 - TODO     
    - Pipeline generation
        - deployments
            - [ ] handle cloud-config & runtime-config
                tfstate => yaml. (network tf =>  net-id => cloud-config-tpl.yml. (( grab tf-exchange.id )) )
            - [ ] generate check-resource script
    - [ ] enable auto-init for manual pipeline
    - migrate manual pipeline to generated pipeline
        - [ ] auto-init
        - [ ] terraform
    - [ ] add tests to validate pipeline generation
    - mattermost:
        - check message

 