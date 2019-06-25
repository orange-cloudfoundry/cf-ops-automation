#!/bin/sh
FLY_CMD=${FLY_CMD:-fly}
FLY_TARGET=${FLY_TARGET:-cf-ops-automation}
CREDENTIAL_FILE=${CREDENTIAL_FILE:-private.yml}


${FLY_CMD} -t ${FLY_TARGET} set-pipeline -p cf-ops-automation -c pipeline.yml -l ${CREDENTIAL_FILE}