
# CI

## ADR

### Run test in online mode

### Rebuild every thing on PR
When a PR is created, and on each commit, we build a docker image associated to this PR. This avoids side effects on lib
 bump, but it slows down test executions (UTs & ITs), as image needs to be build.  
It seems difficult to build a docker image once per PR:
 - we cannot enforce usage of a previous built image  
 
## Running integration tests locally

 1. Ensures variables are consistent with your env. Check files in `ci/bootstrap_coa_env/manual-ITs/*-prereqs.yml`
 2. Run `ci/run-manual-ITs.sh`

## Releasing new COA version

 1. Check current version, and bump to required version if required
 2. `Ship it`

## Resource usage overview
web_vm_type: 1cpu-2g
db_vm_type: 2cpu-8g

worker_vm_type: 4cpu-8g
### current resource usage
* nginx               | 1cpu-1g   |
* ntpd                | 1cpu-1g   |
* zookeeper           | 1cpu-1g   |
* git-server          | 1cpu-1g   |
* web                 | 1cpu-2g   |
* db                  | 2cpu-8g   |
* worker              | 4cpu-8g   |
* worker              | 4cpu-8g   |
* bosh                | 4cpu-16g  | # oversize for our usage

