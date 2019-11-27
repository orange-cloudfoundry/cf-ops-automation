#!/bin/bash
FLY_CMD=${FLY_CMD:-fly}
FLY_TARGET=${FLY_TARGET:-cf-ops-automation}
DEFAULT_CREDENTIAL_FILE="private.yml"
CREDENTIAL_FILE=${CREDENTIAL_FILE:-$DEFAULT_CREDENTIAL_FILE}
DIFF_FILE="${CREDENTIAL_FILE%%-generated.yml}-diff.yml"

if [[ "$CREDENTIAL_FILE" != "$DEFAULT_CREDENTIAL_FILE" ]];then
    touch "${DIFF_FILE}"
    echo "Using diff: $DIFF_FILE"
    spruce merge private.yml "${DIFF_FILE}" > "${CREDENTIAL_FILE}"
    if [ $? -ne 0 ];then
        exit $?
    fi
fi
${FLY_CMD} -t "${FLY_TARGET}" set-pipeline -p cf-ops-automation -c pipeline.yml -l "${CREDENTIAL_FILE}"