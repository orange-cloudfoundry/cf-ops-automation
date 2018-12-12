#!/usr/bin/env bash
set -e
SECRETS=${SECRETS:-../int-secrets}
TEMPLATES=${TEMPLATES:-../paas-templates}
DYNAMIC_DEPLS_FILE_LIST=$(cd $SECRETS && find . -maxdepth 1 -type d -name "*-depls")
for i in ${DYNAMIC_DEPLS_FILE_LIST};
do
 export DYNAMIC_DEPLS_LIST="$DYNAMIC_DEPLS_LIST $(basename $i)"
done
DEPLS_LIST=${DEPLS_LIST:-${DYNAMIC_DEPLS_LIST}}
DEBUG=${DEBUG:=false}


usage(){
    echo "$0" 1>&2
    echo -e "No parameter supported. Use environment variables:" 1>&2
    echo -e "\t IAAS_TYPE: iaas to target. NO DEFAULT VALUE" 1>&2
    echo -e "\t SECRETS: path to secrets directory. DEFAULT: $SECRETS " 1>&2
    echo -e "\t TEMPLATES: path to paas-templates directory. DEFAULT: $TEMPLATES " 1>&2
    echo -e "\t DEPLS_LIST: deployments to process. DEFAULT: [$DYNAMIC_DEPLS_LIST] " 1>&2
    echo -e "\t OUTPUT_DIR: pipeline generation directory. DEFAULT: [./bootstrap-generated] " 1>&2
    echo -e "\t PIPELINE_TYPES: only generate this pipeline. DEFAULT: ALL_PIPELINES " 1>&2
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

if [ -n "${PIPELINE_TYPES}" ]
then
   echo "Only generating pipelines matching ${PIPELINE_TYPES}"
   PIPELINES_RESTRICTION="--input ${PIPELINE_TYPES}"
else
    echo "No PIPELINE_TYPES detected"
fi

echo "Generating pipelines using secrets in $SECRET_DIR to ${OUTPUT_DIR}/pipelines for ${IAAS_TYPE} (Iaas Type)"
for depls in ${DEPLS_LIST};do
    "${CURRENT_SCRIPT_DIR}/generate-depls.rb" -d "${depls}" -p "${SECRET_DIR}" -o "${OUTPUT_DIR}" -t "${TEMPLATES}" --iaas "${IAAS_TYPE}" --no-dump ${PIPELINES_RESTRICTION}
    PIPELINE="${depls}-${PIPELINE_TYPES}-generated"
    echo "${PIPELINE} generated  to ${OUTPUT_DIR}/pipelines"
done

echo "Pipelines generated for: $DEPLS_LIST"
