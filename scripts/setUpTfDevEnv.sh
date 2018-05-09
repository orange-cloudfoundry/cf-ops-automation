#!/usr/bin/env bash

# tune shell check rules: SC2164 https://github.com/koalaman/shellcheck/wiki/SC2164
# shellcheck disable=SC2164

# Goals:
# - Easy local execution allowing direct edition of files in git repos, and their terraform execution in IDE and local.
#   As currently merging of paas-template and paas-secret specs is done by concourse scripts
# Pbs with pure local execution approach
# - may slightly differ from concourse execution (potential mismatch in number & version of providers)

function setUpDevEnv {
    DEV_ENV=$1
    SECRET_REPO=$2
    DEPLOYMENT_PATH=$3

    cd "${WORKDIR}"

    mkdir -p "${DEV_ENV}"
    cd "${DEV_ENV}"

    echo "Prerequisite: have a local copy of paas-template, paas-secret and cf-ops-automation (only for fly interactions)"
    echo "Preparing dev env into $(pwd)"

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
    #ln -nf "${WORKDIR}/${SECRET_REPO}" secret-state-resource

    cd generated-files/
    echo "setting up $(pwd) with hardlinks"

    ln -nfv  "${WORKDIR}/${SECRET_REPO}/${DEPLOYMENT_PATH}/terraform.tfstate" terraform.tfstate
    TEMPLATE_FILES=$(find "${WORKDIR}/paas-template/${DEPLOYMENT_PATH}/spec" -type f )
    SECRET_FILES=$(find "${WORKDIR}/${SECRET_REPO}/${DEPLOYMENT_PATH}/spec"  -type f )

    cd ../spec-applied/
    echo "setting up $(pwd) with hardlinks"

    #set -x
    for f in $TEMPLATE_FILES; do createLink "$f" "${WORKDIR}/paas-template/${DEPLOYMENT_PATH}/spec"; done
    for f in $SECRET_FILES;   do createLink "$f" "${WORKDIR}/${SECRET_REPO}/${DEPLOYMENT_PATH}/spec"; done
    #set +x

    printf "\n Local dev env set up in ${WORKDIR}/${DEV_ENV}, ready to edit tf files there using your favorite IDE with TF HCL syntax support:\n"
    tree --noreport "${WORKDIR}/${DEV_ENV}"

    # You may still have to manually fetch generated terraform.tfvars.json using fly hijack
    # and save it into ${WORKDIR}/${DEV_ENV}/generated-files/terraform.tfvars.json (beware of removing linefeeds)
    # An alternative is to ask concourse to run the generate-manifest.yml tasks through fly execute (see below)

    setup_fly_and_printout_cmds

    display_docker_tf_commands
    display_local_tf_commands
}




# Creates hard link. Since hardlinks don't support directories, we create an emty directory tree first
function createLink() {
    absolute_path=$1
    relative_to_dir=$2

    relative_path=$(realpath "--relative-to=${relative_to_dir}" "${absolute_path}")

    mkdir -p $(dirname "${relative_path}")
    ln -nfv "$f" "${relative_path}";
}



function display_local_tf_commands() {
    printf "\nYou may now then use TF locally with:"
    echo "DEV_ENV=${DEV_ENV}"


    echo "cd ${WORKDIR}/${DEV_ENV}/generated-files"
    echo 'bash -c "\$(curl -fsSL https://raw.github.com/orange-cloudfoundry/terraform-provider-cloudfoundry/master/bin/install.sh)"'
    echo "terraform init -input=false -upgrade -get-plugins=false -plugin-dir=/.terraform/plugins/linux_amd64 ../spec-applied/"
    echo "terraform plan -input=false ../spec-applied/"
}

function display_docker_tf_commands() {

    printf "\nYou may use the docker image with providers configured:\n"

    #echo "# Check current version of image into cf-ops-automation/concourse/tasks/terraform_apply_cloudfoundry.yml"
    #echo "TF_DOCKER_TAG=ad445d6b34dffeadb3c2b26a40dd71de73ec0686"
    export TF_DOCKER_TAG=latest
    #echo "docker pull orangecloudfoundry/terraform:${TF_DOCKER_TAG}"

    echo "docker run     -v ${WORKDIR}/${DEV_ENV}:/mnt/workdir -w /mnt/workdir/generated-files orangecloudfoundry/terraform:${TF_DOCKER_TAG} terraform init -input=false -upgrade -get-plugins=false -plugin-dir=/.terraform/plugins/linux_amd64 ../spec-applied/"
    echo "docker run     -v ${WORKDIR}/${DEV_ENV}:/mnt/workdir -w /mnt/workdir/generated-files orangecloudfoundry/terraform:${TF_DOCKER_TAG} terraform plan -input=false ../spec-applied/"
    echo "# debug if needed using shell"
    echo "docker run -it -v ${WORKDIR}/${DEV_ENV}:/mnt/workdir -w /mnt/workdir/generated-files orangecloudfoundry/terraform:${TF_DOCKER_TAG} /bin/ash"
    echo "docker run     -v ${WORKDIR}/${DEV_ENV}:/mnt/workdir -w /mnt/workdir/generated-files orangecloudfoundry/terraform:${TF_DOCKER_TAG} terraform apply -input=false -auto-approve ../spec-applied/"

}


# An alternative is to ask concourse to run the generate-manifest.yml and terraform_plan_cloudfoundry.yml tasks through fly execute,
# using local version of these tasks (from cf-ops-automation) and local copies of paas-template and paas-secret
# This would be slower than fully local development but enables testing in conditions closer to production without requiring git push delays.

function setup_fly_and_printout_cmds() {

    printf "\nYou may still have to fetch generated terraform.tfvars.json. Below are steps to ask concourse to do so with local copies of your paas-template and paas-secret repos.\n\n"
    echo "The following fly commands can be run within the current shell into which the proper env vars have been defined"
    # This is how to ask concourse to run the generate-manifest.yml tasks through fly execute (see below)
    # using local version of these tasks (from cf-ops-automation) and local copies of paas-template and paas-secret

    #Concourse task invocation extract from concourse/pipelines/template/depls-pipeline.yml.erb:
    #
    #    - task: generate-terraform-tfvars
    #      input_mapping: {scripts-resource: cf-ops-automation, credentials-resource: secrets-<%= depls %>, additional-resource: paas-template-<%=depls %>}
    #      output_mapping: {generated-files: terraform-tfvars}
    #      file: cf-ops-automation/concourse/tasks/generate-manifest.yml
    #      params:
    #        YML_FILES: |
    #          ./credentials-resource/shared/secrets.yml
    #          ./credentials-resource/<%= terraform_config_path %>/secrets/meta.yml
    #          ./credentials-resource/<%= terraform_config_path %>/secrets/secrets.yml
    #        YML_TEMPLATE_DIR: additional-resource/<%= terraform_config_path %>/template
    #        CUSTOM_SCRIPT_DIR: additional-resource/<%= terraform_config_path %>/template
    #        SUFFIX: -tpl.tfvars.yml
    #        IAAS_TYPE: ((iaas-type))


    # Corresponding fly execute command (still missing some args)

    DEPLOYMENT_PATH=ops-depls/cloudfoundry/terraform-config
    SECRET_REPO=int-secrets


    export IAAS_TYPE='openstack'
    export CUSTOM_SCRIPT_DIR=additional-resource/${DEPLOYMENT_PATH}/template
    export  YML_TEMPLATE_DIR=additional-resource/${DEPLOYMENT_PATH}/template
    #export SPRUCE_FILE_BASE_PATH=
    export YML_FILES="./credentials-resource/shared/secrets.yml"
    export SUFFIX="-tpl.tfvars.yml"

    echo "---- Fly cmd for the tf vars generation (should take close to 3 mins)---"
    echo fly -t int.micro execute \
            -c "${WORKDIR}/cf-ops-automation/concourse/tasks/generate-manifest.yml"  \
            -i "scripts-resource=${WORKDIR}/cf-ops-automation"  \
            -i "credentials-resource=${WORKDIR}/${SECRET_REPO}"  \
            -i "additional-resource=${WORKDIR}/paas-template" \
            -o "generated-files=${WORKDIR}/${DEV_ENV}/generated-files"

    printf "\nYou may also ask concourse to execute the tf plan/apply using your local spec files:\n"
    echo "--- Fly cmd for the TF plan ---"

    #    - task: terraform-plan
    #      input_mapping: {secret-state-resource: secrets-<%= depls %>,spec-resource: paas-template-<%=depls %>}
    #      file: cf-ops-automation/concourse/tasks/terraform_plan_cloudfoundry.yml
    #      params:
    #        SPEC_PATH: "<%= terraform_config_path %>/spec"
    #        SECRET_STATE_FILE_PATH: "<%= terraform_config_path %>"
    #        IAAS_SPEC_PATH: "<%= terraform_config_path %>/spec-((iaas-type))"
    #

    export SPEC_PATH=${DEPLOYMENT_PATH}/spec
    export SECRET_STATE_FILE_PATH=${DEPLOYMENT_PATH}
    export IAAS_SPEC_PATH=${DEPLOYMENT_PATH}/spec-${IAAS_TYPE}

    mkdir -p ${WORKDIR}/${DEV_ENV}/tf-plan-generated-files
    mkdir -p ${WORKDIR}/${DEV_ENV}/tf-plan-spec-applied

    echo fly -t int.micro execute \
            -c "${WORKDIR}/cf-ops-automation/concourse/tasks/terraform_plan_cloudfoundry.yml" \
            -i "secret-state-resource=${WORKDIR}/${SECRET_REPO}" \
            -i "spec-resource=${WORKDIR}/paas-template" \
            -i "terraform-tfvars=${WORKDIR}/${DEV_ENV}/generated-files" \
            -o "generated-files=${WORKDIR}/${DEV_ENV}/generated-files" \
            -o "spec-applied=${WORKDIR}/${DEV_ENV}/spec-applied"

    echo
    echo "Note: this may override your paas-template and paas-secret files. To avoid this, don't use the hardlinks set up"
    echo "rm -rfi ${WORKDIR}/${DEV_ENV}/generated-files ${WORKDIR}/${DEV_ENV}/spec-applied"

    echo "--- Fly cmd for the TF apply ---"

    #    - task: terraform-apply
    #      input_mapping: {secret-state-resource: secrets-<%= depls %>,spec-resource: paas-template-<%=depls %>}
    #      output_mapping: {generated-files: terraform-cf}
    #      file: cf-ops-automation/concourse/tasks/terraform_apply_cloudfoundry.yml
    #      params:
    #        SPEC_PATH: "<%= terraform_config_path %>/spec"
    #        SECRET_STATE_FILE_PATH: "<%= terraform_config_path %>"
    #        IAAS_SPEC_PATH: "<%= terraform_config_path %>/spec-((iaas-type))"

    echo fly -t int.micro execute \
        -c "${WORKDIR}/cf-ops-automation/concourse/tasks/terraform_apply_cloudfoundry.yml" \
        -i "secret-state-resource=${WORKDIR}/${SECRET_REPO}" \
        -i "spec-resource=${WORKDIR}/paas-template" \
        -i "terraform-tfvars=${WORKDIR}/${DEV_ENV}/generated-files" \
        -o "generated-files=${WORKDIR}/${DEV_ENV}/generated-files" \
        -o "spec-applied=${WORKDIR}/${DEV_ENV}/spec-applied"
}

#Intellij fails to recognize heredoc within functions
#As a workaround, define them within variables using this trick
# https://stackoverflow.com/questions/1167746/how-to-assign-a-heredoc-value-to-a-variable-in-bash

MSG1=$(cat << 'EOF1'

you may proceed with setting up your env with the following commands, eg. for Guillaume's env:
WORKDIR=/home/guillaume/code/workspaceElPaasov14

setUpDevEnv terraform-prod-micro-deps-env    bosh-cloudwatt-secrets          micro-depls/terraform-config
setUpDevEnv terraform-preprod-micro-deps-env bosh-cloudwatt-preprod-secrets  micro-depls/terraform-config
setUpDevEnv terraform-preprod-env            bosh-cloudwatt-preprod-secrets  ops-depls/cloudfoundry/terraform-config
setUpDevEnv terraform-preprod-ops-deps-env   bosh-cloudwatt-preprod-secrets  ops-depls/cloudfoundry/terraform-config
setUpDevEnv terraform-prod-ops-deps-env      bosh-cloudwatt-secrets          ops-depls/cloudfoundry/terraform-config
setUpDevEnv terraform-int-ops-deps-env       int-secrets                     ops-depls/cloudfoundry/terraform-config
EOF1
)

echo "$MSG1"