#!/usr/bin/env bash
set -e

CURRENT_SCRIPT_DIR=$(realpath $0|xargs dirname)
COA_DIR=$(realpath "$CURRENT_SCRIPT_DIR/..")

DEPLS=${DEPLS:-micro-depls}
PREFIX=${PREFIX:-""}
SECRETS=${SECRETS:-$(realpath ${COA_DIR}/../int-secrets)}
PAAS_TEMPLATES=${PAAS_TEMPLATES:-$(realpath ${COA_DIR}/../paas-templates)}
OUTPUT_DIR=${OUTPUT_DIR:-$(realpath ${COA_DIR}/bootstrap-generated)}
PIPELINE_NAME=${PIPELINE_NAME:-${DEPLS}-bosh}
TEAM=${TEAM:-${DEPLS}}

FLY_CMD=${FLY_CMD:=fly}
FLY_TARGET=${FLY_TARGET:=int}
${CURRENT_SCRIPT_DIR}/generate-depls.rb --depls "${DEPLS}" -p "${SECRETS}" -t "${PAAS_TEMPLATES}" -a "${COA_DIR}" -o "${OUTPUT_DIR}" --no-dump
echo "Removing empty pipelines"
set +e
EMPTY_PIPELINES=$(grep -l '\- name: this-is-an-empty-pipeline' "${OUTPUT_DIR}/pipelines/${DEPLS}"-*.yml)
set -e
for empty_pipeline in ${EMPTY_PIPELINES}; do
 rm -v "${empty_pipeline}"
done
echo "Removed empty pipelines"

CONCOURSE_CONFIG_FILES=$(ls ${SECRETS}/coa/config/*.yml| grep -v "\-pipeline.yml")
for VAR_FILE in ${CONCOURSE_CONFIG_FILES};do
    VAR_FILES="$VAR_FILES -l $VAR_FILE"
done

PIPELINE_VAR_FILENAME="${SECRETS}/coa/config/credentials-${PIPELINE_NAME}-pipeline.yml"
PIPELINE_VAR=""
if [[ -e "${PIPELINE_VAR_FILENAME}" ]];then
    PIPELINE_VAR="-l ${PIPELINE_VAR_FILENAME}"
fi

PIPELINE_FILE_PATH="${OUTPUT_DIR}/pipelines/${PIPELINE_NAME}-generated.yml"
if [ ! -e "${PIPELINE_FILE_PATH}" ]; then
    echo "SKipping ${PIPELINE_FILE_PATH} does not exit"
    exit
fi
PIPELINE_PUBLIC_NAME="${PREFIX}${PIPELINE_NAME}-generated"
"${FLY_CMD}" validate-pipeline -c "${PIPELINE_FILE_PATH}"
echo "switch team"
"${FLY_CMD}" -t "${FLY_TARGET}" etg -n "${TEAM}"
echo "set pipeline"
"${FLY_CMD}" -t "${FLY_TARGET}" set-pipeline ${FLY_SET_PIPELINE_OPTION} -p "${PIPELINE_PUBLIC_NAME}"  -c "${PIPELINE_FILE_PATH}" \
  ${VAR_FILES} \
  ${PIPELINE_VAR} \
  -l "${PAAS_TEMPLATES}/${DEPLS}/root-deployment.yml"
"${FLY_CMD}" -t "${FLY_TARGET}" unpause-pipeline -p "${PIPELINE_PUBLIC_NAME}"


