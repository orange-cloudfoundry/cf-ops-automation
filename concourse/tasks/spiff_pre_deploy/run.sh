#!/bin/sh

set -e

CURRENT_DIR=$(pwd)
OUTPUT_DIR=${OUTPUT_DIR:-${CURRENT_DIR}/generated-files}
COMMON_SCRIPT_DIR=${COMMON_SCRIPT_DIR:-scripts-resource/scripts/manifest}

cp -r additional-resource/. ${OUTPUT_DIR}/

if [ -n "$CUSTOM_SCRIPT_DIR" ]; then
    if [ -f "$CUSTOM_SCRIPT_DIR/pre-deploy.sh" ]; then
        echo "pre deploy script detected"
        chmod +x $CUSTOM_SCRIPT_DIR/pre-deploy.sh
        GENERATE_DIR=${OUTPUT_DIR} BASE_TEMPLATE_DIR=${CUSTOM_SCRIPT_DIR} ${CUSTOM_SCRIPT_DIR}/pre-deploy.sh
    elif [ -f "$CUSTOM_SCRIPT_DIR/pre-bosh-deploy.sh" ]; then
        echo "**deprecated** LEGACY pre bosh deploy script detected"
        echo "Please rename pre-bosh-deploy.sh to pre-deploy.sh to be compliant"
        chmod +x $CUSTOM_SCRIPT_DIR/pre-bosh-deploy.sh
        GENERATE_DIR=${OUTPUT_DIR} BASE_TEMPLATE_DIR=${CUSTOM_SCRIPT_DIR} ${CUSTOM_SCRIPT_DIR}/pre-bosh-deploy.sh
    else
        echo "ignoring pre-deploy. No $CUSTOM_SCRIPT_DIR/pre-deploy.sh or pre-bosh-deploy.sh detected"
    fi
else
    echo "ignoring pre-deploy. No $CUSTOM_SCRIPT_DIR/pre-deploy.sh or pre-bosh-deploy.sh detected"
fi
