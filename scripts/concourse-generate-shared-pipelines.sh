#!/usr/bin/env bash
set -e
SECRETS=${SECRETS:-../int-secrets}
TEMPLATES=${TEMPLATES:-../paas-templates}
DEBUG=${DEBUG:=false}

usage(){
    echo "$0" 1>&2
    echo -e "No parameter supported. Use environment variables:" 1>&2
    echo -e "\t IAAS_TYPE: iaas to target. NO DEFAULT VALUE" 1>&2
    echo -e "\t PROFILES: profiles to apply. NO DEFAULT VALUE" 1>&2
    echo -e "\t SECRETS: path to secrets directory. DEFAULT: $SECRETS " 1>&2
    echo -e "\t TEMPLATES: path to paas-templates directory. DEFAULT: $TEMPLATES " 1>&2
    echo -e "\t OUTPUT_DIR: pipeline generation directory. DEFAULT: [./bootstrap-generated] " 1>&2
    echo -e "\t PIPELINE_TYPE: only generate this pipeline. DEFAULT: ALL_PIPELINES " 1>&2
    exit 1
}

if [ $# -ne 0 ]
then
    usage
fi

CURRENT_SCRIPT_DIR=$(realpath $0|xargs dirname)
if [ "$SCRIPT_DIR" == "." ]
then
    SCRIPT_DIR=..
fi
ROOT_DIR=${CURRENT_SCRIPT_DIR%scripts}

set +e
SECRET_DIR=$(readlink -e ${SECRETS})
set -e
if [ "$SECRET_DIR" == "" ]
then
    echo "SECRETS ($SECRETS) does not exist" 1>&2
    usage
    exit 1
fi

if [ -z "${OUTPUT_DIR}" ]
then
    OUTPUT_DIR=$(readlink -f ${ROOT_DIR}/bootstrap-generated)
fi
mkdir -p ${OUTPUT_DIR}/pipelines

if [ -n "${PIPELINE_TYPE}" ]
then
   echo "Only generating pipelines matching ${PIPELINE_TYPE}"
   PIPELINES_RESTRICTION="--input ${PIPELINE_TYPE}"
else
    echo "No PIPELINE_TYPE detected"
fi

if [ "$PROFILES_AUTOSORT" = "false" ]; then
    echo "Disabling profiles auto sort"
    PROFILES_AUTOSORT_OPTION="--no-profiles-auto-sort"
else
    echo "Enabling profiles auto sort"
    PROFILES_AUTOSORT_OPTION="--profiles-auto-sort"
fi

echo "Generating shared pipelines using secrets in $SECRET_DIR to ${OUTPUT_DIR}/pipelines for ${IAAS_TYPE} (Iaas Type), with profiles: [${PROFILES}]"
"${CURRENT_SCRIPT_DIR}/generate-depls.rb" -p "${SECRET_DIR}" -o "${OUTPUT_DIR}" -t "${TEMPLATES}" --iaas "${IAAS_TYPE}" ${PROFILES_AUTOSORT_OPTION} --profiles "${PROFILES}" --no-dump ${PIPELINES_RESTRICTION}
PIPELINE="shared-${PIPELINE_TYPE}-generated"
echo "${PIPELINE} generated  to ${OUTPUT_DIR}/pipelines"

