#!/usr/bin/env bash
set -e
SECRETS=${SECRETS:-$(pwd)/../../int-secrets}
FLY_TARGET=${FLY_TARGET:-fe-int}
SKIP_TRIGGER=${SKIP_TRIGGER:=false}
DEBUG=${DEBUG:=false}
FLY_CMD=${FLY_CMD:=fly}
usage(){
    echo "$0" 1>&2
    echo -e "No parameter supported. Use environment variables:" 1>&2
    echo -e "\t FLY_TARGET: fly target name to use. DEFAULT: $FLY_TARGET" 1>&2
    echo -e "\t FLY_CMD: fly binary name to use. DEFAULT: $FLY_CMD" 1>&2
    echo -e "\t SECRETS: path to secrets directory. DEFAULT: $SECRETS" 1>&2
    echo -e "\t SKIP_TRIGGER: skip job triggering after pipeline loading. DEFAULT: [$SKIP_TRIGGER]" 1>&2
    echo -e "\t FLY_SET_PIPELINE_OPTION: set custom option like '--non-interactive'. DEFAULT: empty" 1>&2
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
SCRIPT_DIR=${CURRENT_SCRIPT_DIR%/scripts}

set +e
SECRET_DIR=$(readlink -e ${SECRETS})
set -e
if [ "$SECRET_DIR" == "" ]
then
    echo "SECRETS ($SECRETS) does not exist" 1>&2
    exit 1
fi

echo "Deploy on ${FLY_TARGET} using secrets in $SECRET_DIR"

PIPELINE="bootstrap-all-init-pipelines"
echo "Load ${PIPELINE} on ${FLY_TARGET}"
set +e
${FLY_CMD} -t ${FLY_TARGET} set-pipeline ${FLY_SET_PIPELINE_OPTION} -p ${PIPELINE} -c ${SCRIPT_DIR}/concourse/pipelines/${PIPELINE}.yml  \
            -l "${SECRET_DIR}/micro-depls/concourse-micro/pipelines/credentials-auto-init.yml" \
            -l "${SECRET_DIR}/micro-depls/concourse-micro/pipelines/credentials-iaas-specific.yml" \
            -l "${SECRET_DIR}/micro-depls/concourse-micro/pipelines/credentials-git-config.yml"
set -e
${FLY_CMD} -t ${FLY_TARGET} unpause-pipeline -p ${PIPELINE}
if [ "$SKIP_TRIGGER" != "true" ]
then
    ${FLY_CMD} -t ${FLY_TARGET} trigger-job -j "${PIPELINE}/bootstrap-pipelines"
fi
