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