#!/usr/bin/env bash

function setUpDevEnv {
    SECRET_REPO=$1
    DEV_ENV=$2
    DEPLOYMENT_PATH=$3

    cd $WORKDIR

    mkdir -p $DEV_ENV
    cd $DEV_ENV

    mkdir -p generated-files
    mkdir -p spec-applied

    cd generated-files/

    # ln -s secret-state-resource ${WORKDIR}/${SECRET_REPO}/ops-depls/cloudfoundry/terraform-config

    ln -s  ${WORKDIR}/${SECRET_REPO}/ops-depls/cloudfoundry/terraform-config/terraform.tfstate terraform.tfstate

    #TODO: Manually fetch terraform.tfvars.json vi terraform.tfvars.json


    TEMPLATE_FILES=$(find ${WORKDIR}/paas-template/${DEPLOYMENT_PATH}/ -mindepth 1 -maxdepth 1 -type f  )
    SECRET_FILES=$(find ${WORKDIR}/${SECRET_REPO}/${DEPLOYMENT_PATH}/  -mindepth 1 -maxdepth 1 -type f )
    cd ../spec-applied/
    for f in $TEMPLATE_FILES; do name=$(basename $f); ln -ns $f $name ; done;
    for f in $SECRET_FILES; do name=$(basename $f); ln -ns $f $name ; done;
    ln -ns ${WORKDIR}/paas-template/${DEPLOYMENT_PATH}/modules modules

}

WORKDIR=/home/guillaume/code/workspaceElPaasov14/


setUpDevEnv bosh-cloudwatt-preprod-secrets terraform-preprod-env ops-depls/cloudfoundry/terraform-config/spec
setUpDevEnv bosh-cloudwatt-secrets terraform-prod-env ops-depls/cloudfoundry/terraform-config/spec

# You may now try local usage of TF

cd ${WORKDIR}/terraform-preprod-env/generated-files

bash -c "$(curl -fsSL https://raw.github.com/orange-cloudfoundry/terraform-provider-cloudfoundry/master/bin/install.sh)"

terraform init -input=false -upgrade ../spec-applied/

terraform plan -input=false ../spec-applied/

# An alternative is to ask concourse to run the generate-manifest.yml and terraform_plan_cloudfoundry.yml tasks through fly execute,
# using local version of these tasks (from cf-ops-automation) and local copies of paas-template and paas-secret
# This would be slower than fully local development but enables testing in conditions closer to production without requiring git push delays.
