#!/usr/bin/env bash
set -e
SECRETS=${SECRETS:-../preprod-secrets}
FLY_TARGET=${FLY_TARGET:-cw-pp-micro}
DEPLS_LIST=${DEPLS_LIST:-"micro-depls master-depls ops-depls expe-depls"}
SKIP_TRIGGER=${SKIP_TRIGGER:=false}
DEBUG=${DEBUG:=false}


usage(){
    echo "$0" 1>&2
    echo -e "No parameter supported. Use environment variables:" 1>&2
    echo -e "\t FLY_TARGET: fly target name to use. DEFAULT: $FLY_TARGET " 1>&2
    echo -e "\t SECRETS: path to secrets directory. DEFAULT: $SECRETS " 1>&2
    echo -e "\t DEPLS_LIST: deployments to process. DEFAULT: [$DEPLS_LIST] " 1>&2
    echo -e "\t SKIP_TRIGGER: skip job triggering after pipeline loading. DEFAULT: [$SKIP_TRIGGER] " 1>&2
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
SCRIPT_DIR=${CURRENT_SCRIPT_DIR%scripts}

set +e
SECRET_DIR=$(readlink -e ${SECRETS})
set -e
if [ "$SECRET_DIR" == "" ]
then
    echo "SECRETS ($SECRETS) does not exist" 1>&2
    usage
    exit 1
fi

OUTPUT_DIR=$(readlink -f ${SCRIPT_DIR}/boostrap-generated)
mkdir -p ${OUTPUT_DIR}/pipelines

echo "Deploy on ${FLY_TARGET} using secrets in $SECRET_DIR"
for depls in ${DEPLS_LIST};do
    cd ${SCRIPT_DIR}/concourse
    ./generate-depls.rb -d ${depls} -p ${SECRET_DIR} -o ${OUTPUT_DIR}
    PIPELINE="${depls}-init-generated"
    cd ${SCRIPT_DIR}
    echo "Load ${PIPELINE} on ${FLY_TARGET}"
    set +e
    fly -t ${FLY_TARGET} set-pipeline -p ${PIPELINE} -c ${OUTPUT_DIR}/pipelines/${PIPELINE}.yml  -l ${SECRET_DIR}/micro-depls/concourse-micro/pipelines/credentials-auto-init.yml
    set -e
    fly -t ${FLY_TARGET} unpause-pipeline -p ${PIPELINE}
    if [ "$SKIP_TRIGGER" != "true" ]
    then
        fly -t ${FLY_TARGET} trigger-job -j "${PIPELINE}/update-pipeline-${depls}"
    fi
done

