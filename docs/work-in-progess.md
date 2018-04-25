# current development status

- Pipeline generation
  - [X] auto-init
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
    - [X] generate check-resource script
    - [ ] better support of bosh release not available on bosh.io
  - cf-apps
    - [X] support/test multi app deployment.
  - [ ] enable auto-init for manual pipeline
  - migrate manual pipeline to generated pipeline
  - [X] auto-init
  - [X] terraform
  - [ ] add tests to validate pipeline generation
  - mattermost:
  - check message
