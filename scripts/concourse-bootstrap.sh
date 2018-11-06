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

if [ -d ${SECRET_DIR}/coa/config ];then
    CONFIG_DIR=${SECRET_DIR}/coa/config
else
    CONFIG_DIR=${SECRET_DIR}/micro-depls/concourse-micro/pipelines
fi
echo "COA config directory detected: <${CONFIG_DIR}>"

FILTERED_CONFIG_FILES=$(cd ${CONFIG_DIR} && ls -1 credentials-*.yml|grep -v pipeline)
VARS_FILES=""
for config_file in ${FILTERED_CONFIG_FILES}; do
    VARS_FILES="${VARS_FILES}-l \"${CONFIG_DIR}/${config_file}\" "
done
echo ${VARS_FILES}
set +e
set -x
${FLY_CMD} -t ${FLY_TARGET} set-pipeline ${FLY_SET_PIPELINE_OPTION} -p ${PIPELINE} -c ${SCRIPT_DIR}/concourse/pipelines/${PIPELINE}.yml  \
            ${VARS_FILES}
set +x
set -e
${FLY_CMD} -t ${FLY_TARGET} unpause-pipeline -p ${PIPELINE}
if [ "$SKIP_TRIGGER" != "true" ]
then
    ${FLY_CMD} -t ${FLY_TARGET} trigger-job -j "${PIPELINE}/bootstrap-pipelines"
fi
