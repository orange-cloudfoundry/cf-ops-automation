#!/usr/bin/env bash
set -e


CURRENT_SCRIPT_DIR=$(realpath "$0"|xargs dirname)
COA_DIR=$(realpath "$CURRENT_SCRIPT_DIR/..")

DEPLS=${DEPLS:-micro}
PREFIX=${PREFIX:-""}
SECRETS=${SECRETS:-$(realpath ${COA_DIR}/../int-secrets)}
PAAS_TEMPLATES=${PAAS_TEMPLATES:-$(realpath ${COA_DIR}/../paas-templates)}
PIPELINE_NAME=${PIPELINE_NAME:-sync-feature-branches}
TEAM=${TEAM:-main}

FLY_CMD=${FLY_CMD:=fly}
FLY_TARGET=${FLY_TARGET:=int}

CONCOURSE_CONFIG_FILES=$(ls ${SECRETS}/coa/config/*.yml| grep -v "\-pipeline.yml")

for VAR_FILE in ${CONCOURSE_CONFIG_FILES};do
    VAR_FILES="$VAR_FILES -l $VAR_FILE"
done

PIPELINE_VAR_FILENAME="${SECRETS}/coa/config/credentials-${PIPELINE_NAME}-pipeline.yml"
PIPELINE_VAR=""
if [[ -e "${PIPELINE_VAR_FILENAME}" ]];then
    PIPELINE_VAR="-l ${PIPELINE_VAR_FILENAME}"
fi

PIPELINE_FILE_PATH="${COA_DIR}/concourse/pipelines/${PIPELINE_NAME}.yml"
"${FLY_CMD}" validate-pipeline -c "${PIPELINE_FILE_PATH}"
echo "switch team"
"${FLY_CMD}" -t "${FLY_TARGET}" etg -n "${TEAM}"
echo "set pipeline"
"${FLY_CMD}" -t "${FLY_TARGET}" set-pipeline -p "${PREFIX}${PIPELINE_NAME}"  -c "${PIPELINE_FILE_PATH}" \
  ${VAR_FILES} \
  ${PIPELINE_VAR} \
  -l "${PAAS_TEMPLATES}/${DEPLS}-depls/root-deployment.yml"
"${FLY_CMD}" -t ${FLY_TARGET} unpause-pipeline -p "${PIPELINE_NAME}"


