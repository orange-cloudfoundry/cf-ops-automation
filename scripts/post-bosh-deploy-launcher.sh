#!/bin/sh
set -e

CURRENT_DIR=$(pwd)
OUTPUT_DIR=${OUTPUT_DIR:-${CURRENT_DIR}/generated-files}
COMMON_SCRIPT_DIR=${COMMON_SCRIPT_DIR:-scripts-resource/scripts}
SECRETS_DIR=${SECRETS_DIR:-credentials-resource}

if [ -n "$CUSTOM_SCRIPT_DIR" -a  -f "$CUSTOM_SCRIPT_DIR/post-bosh-deploy.sh" ]
then
    echo "post bosh deploy script detected"
    chmod +x $CUSTOM_SCRIPT_DIR/post-bosh-deploy.sh
    GENERATE_DIR=${OUTPUT_DIR} BASE_TEMPLATE_DIR=${CUSTOM_SCRIPT_DIR} ${CUSTOM_SCRIPT_DIR}/post-bosh-deploy.sh
fi
