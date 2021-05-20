#!/bin/sh

#!/usr/bin/env bash
set -e

#export FLY_TARGET=k8s-int
export FLY_TARGET=cf-ops-automation
export SKIP_TRIGGER=true
#export FLY_CMD=fly-5.6


FLY_CMD=${FLY_CMD:=fly}
FLY_TARGET=${FLY_TARGET:=int}

TASK_FILE_PATH="$(dirname $0)/tasks/run-ITs/task.yml"
PIPELINE_VARIABLES="$(dirname $0)/private.yml"


COA_LOGS_DIR=/tmp/coa-logs
rm -rf "${COA_LOGS_DIR}"
mkdir -p "${COA_LOGS_DIR}"
COA_PREREQS_DIR=/tmp/coa-prereqs
rm -rf "${COA_PREREQS_DIR}"
mkdir -p "${COA_PREREQS_DIR}"


echo "manually execute ITs $(basename "${TASK_FILE_PATH}") on ${FLY_TARGET}"
"${FLY_CMD}" -t "${FLY_TARGET}" execute  -c "${TASK_FILE_PATH}" \
    -l "${PIPELINE_VARIABLES}" \
    -o coa-logs="${COA_LOGS_DIR}" \
    -o prereqs="${COA_PREREQS_DIR}" \
    -i cf-ops-automation=../

