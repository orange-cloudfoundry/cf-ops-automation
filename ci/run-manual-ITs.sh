#!/bin/sh

#!/usr/bin/env bash
set -e

export FLY_TARGET=fe-int-concourse
export SKIP_TRIGGER=true
export FLY_CMD=fly-5.2

FLY_CMD=${FLY_CMD:=fly}
FLY_TARGET=${FLY_TARGET:=fe-int}

TASK_FILE_PATH="ci/tasks/run-ITs/task.yml"


COA_LOGS_DIR=/tmp/coa-logs
rm -rf ${COA_LOGS_DIR}
mkdir -p ${COA_LOGS_DIR}
COA_PREREQS_DIR=/tmp/coa-prereqs
rm -rf ${COA_PREREQS_DIR}
mkdir -p ${COA_PREREQS_DIR}


echo "set pipeline $(basename ${TASK_FILE_PATH}) on ${FLY_TARGET}"
${FLY_CMD} -t ${FLY_TARGET} execute  -c ${TASK_FILE_PATH} \
    -l ci/private-concourse-dev.yml \
    -o coa-logs=${COA_LOGS_DIR} \
    -o prereqs=${COA_PREREQS_DIR} \
    -i cf-ops-automation=.

