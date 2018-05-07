#!/usr/bin/env bash

# Goals:
# - Easy local execution allowing direct edition of files in git repos, and their terraform execution in IDE and local.
#   As currently merging of paas-template and paas-secret specs is done by concourse scripts
# Pbs with pure local execution approach
# - may slightly differ from concourse execution (poetential mismatch in number & version of providers)

function setUpDevEnv {
    DEV_ENV=$1
    SECRET_REPO=$2
    DEPLOYMENT_PATH=$3

    cd $WORKDIR

    mkdir -p $DEV_ENV
    cd $DEV_ENV
    echo "preparing dev env into $(pwd)"

    # Set up git so that we can version our local dev env changes
    if [ ! -d ".git" ]; then
        git init

        #Intellij bash plugin doesn't like the heredoc syntax :-(
        #cat <<- EOF > .gitignore
        #.idea/
        #/generated-files/.terraform/
        #EOF

        echo ".idea/" > .gitignore
        echo "/generated-files/.terraform/" >> .gitignore

        git add .gitignore
        git commit -m "auto generated" .gitignore
    fi


    mkdir -p generated-files
    mkdir -p spec-applied
    # Skipping secret resource not used by terraform
    #ln -nf ${WORKDIR}/${SECRET_REPO} secret-state-resource
    cd generated-files/

    echo "setting up $(pwd) with hardlinks"

    ln -nfv  ${WORKDIR}/${SECRET_REPO}/${DEPLOYMENT_PATH}/terraform.tfstate terraform.tfstate


    TEMPLATE_FILES=$(find ${WORKDIR}/paas-template/${DEPLOYMENT_PATH}/spec -type f )
    SECRET_FILES=$(find ${WORKDIR}/${SECRET_REPO}/${DEPLOYMENT_PATH}/spec  -type f )
    cd ../spec-applied/
    echo "setting up $(pwd) with hardlinks"


    #set -x
    for f in $TEMPLATE_FILES; do createLink $f ${WORKDIR}/paas-template/${DEPLOYMENT_PATH}/spec; done
    for f in $SECRET_FILES;   do createLink $f ${WORKDIR}/${SECRET_REPO}/${DEPLOYMENT_PATH}/spec; done
    #set +x

    echo "Result of set up is:"
    tree ${WORKDIR}/${DEV_ENV}

    echo
    echo "DEV_ENV=${DEV_ENV}"
    echo "$MSG2"
}




# Creates hard link. Since hardlinks don't support directories, we create an emty directory tree first
function createLink() {
    absolute_path=$1
    relative_to_dir=$2

    relative_path=$(realpath --relative-to=${relative_to_dir} ${absolute_path})

    mkdir -p $(dirname $relative_path)
    ln -nfv $f $relative_path;
}


#Intellij fails to recognize heredoc within functions
#As a workaround, define them within variables using this trick
# https://stackoverflow.com/questions/1167746/how-to-assign-a-heredoc-value-to-a-variable-in-bash

MSG1=$(cat << 'EOF1'

you may proceed with setting up your env with the following commands:
WORKDIR=/home/guillaume/code/workspaceElPaasov14

setUpDevEnv terraform-prod-micro-deps-env    bosh-cloudwatt-secrets          micro-depls/terraform-config
setUpDevEnv terraform-preprod-micro-deps-env bosh-cloudwatt-preprod-secrets  micro-depls/terraform-config
setUpDevEnv terraform-preprod-env            bosh-cloudwatt-preprod-secrets  ops-depls/cloudfoundry/terraform-config
setUpDevEnv terraform-preprod-ops-deps-env   bosh-cloudwatt-preprod-secrets  ops-depls/cloudfoundry/terraform-config
setUpDevEnv terraform-prod-ops-deps-env      bosh-cloudwatt-secrets          ops-depls/cloudfoundry/terraform-config
setUpDevEnv terraform-int-ops-deps-env       int-secrets                     ops-depls/cloudfoundry/terraform-config
EOF1
)

MSG2=$(cat << 'EOF2'
# TODO: You may still have to manually fetch generated terraform.tfvars.json using fly hijack
# and save it into ${WORKDIR}/${DEV_ENV}/generated-files/terraform.tfvars.json (beware of removing linefeeds)
# An alternative is to ask concourse to run the generate-manifest.yml tasks through fly execute (see below)

# You may now then use TF locally with:

cd ${WORKDIR}/${DEV_ENV}/generated-files
bash -c "\$(curl -fsSL https://raw.github.com/orange-cloudfoundry/terraform-provider-cloudfoundry/master/bin/install.sh)"
terraform init -input=false -upgrade -get-plugins=false -plugin-dir=/.terraform/plugins/linux_amd64 ../spec-applied/
terraform plan -input=false ../spec-applied/

# or using the docker image with providers configured

# Check current version of image into cf-ops-automation/concourse/tasks/terraform_apply_cloudfoundry.yml
TF_DOCKER_TAG=ad445d6b34dffeadb3c2b26a40dd71de73ec0686
docker pull orangecloudfoundry/terraform:${TF_DOCKER_TAG}

docker run     -v ${WORKDIR}/${DEV_ENV}:/mnt/workdir -w /mnt/workdir/generated-files orangecloudfoundry/terraform:${TF_DOCKER_TAG} terraform init -input=false -upgrade -get-plugins=false -plugin-dir=/.terraform/plugins/linux_amd64 ../spec-applied/
docker run     -v ${WORKDIR}/${DEV_ENV}:/mnt/workdir -w /mnt/workdir/generated-files orangecloudfoundry/terraform:${TF_DOCKER_TAG} terraform plan -input=false ../spec-applied/
# debug if needed using shell
docker run -it -v ${WORKDIR}/${DEV_ENV}:/mnt/workdir -w /mnt/workdir/generated-files orangecloudfoundry/terraform:${TF_DOCKER_TAG} /bin/ash
EOF2
)

# An alternative is to ask concourse to run the generate-manifest.yml and terraform_plan_cloudfoundry.yml tasks through fly execute,
# using local version of these tasks (from cf-ops-automation) and local copies of paas-template and paas-secret
# This would be slower than fully local development but enables testing in conditions closer to production without requiring git push delays.


MSG3=$(cat << 'EOF3'
# Asking concourse to run the generate-manifest.yml tasks through fly execute (see below)
# using local version of these tasks (from cf-ops-automation) and local copies of paas-template and paas-secret

#Concourse task invocation extract from concourse/pipelines/template/depls-pipeline.yml.erb:

    - task: generate-terraform-tfvars
      input_mapping: {scripts-resource: cf-ops-automation, credentials-resource: secrets-<%= depls %>, additional-resource: paas-template-<%=depls %>}
      output_mapping: {generated-files: terraform-tfvars}
      file: cf-ops-automation/concourse/tasks/generate-manifest.yml
      params:
        YML_FILES: |
          ./credentials-resource/shared/secrets.yml
          ./credentials-resource/<%= terraform_config_path %>/secrets/meta.yml
          ./credentials-resource/<%= terraform_config_path %>/secrets/secrets.yml
        YML_TEMPLATE_DIR: additional-resource/<%= terraform_config_path %>/template
        CUSTOM_SCRIPT_DIR: additional-resource/<%= terraform_config_path %>/template
        SUFFIX: -tpl.tfvars.yml
        IAAS_TYPE: ((iaas-type))

# Corresponding fly execute command (still missing some args)

fly -t micro execute \
        -c concourse/tasks/generate-manifest.yml  \
        -i scripts-resource=${WORKDIR}/cf-ops-automation  \
        -i credentials-resource=${SECRET_REPO}  \
        -i additional-resource=${WORKDIR}/paas-template/${DEPLOYMENT_PATH}/spec \
        -o generated-files=${WORKDIR}/${DEV_ENV}/generated-files

        -i IAAS_TYPE='openstack'
        -i CUSTOM_SCRIPT_DIR=
        -i YML_TEMPLATE_DIR=
        -i SPRUCE_FILE_BASE_PATH=
        -i YML_FILES=
        -i SUFFIX=
EOF3
)




echo "$MSG1"