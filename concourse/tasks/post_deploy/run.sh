#!/bin/bash
set -e

CURRENT_DIR=$(pwd)
OUTPUT_DIR=${OUTPUT_DIR:-${CURRENT_DIR}/generated-files}
COMMON_SCRIPT_DIR=${COMMON_SCRIPT_DIR:-scripts-resource/scripts}
SECRETS_DIR=${SECRETS_DIR:-credentials-resource}

cp -r additional-resource/. $OUTPUT_DIR/
cf --version

if [ -n "$CUSTOM_SCRIPT_DIR" ]; then
 if [ -f "$CUSTOM_SCRIPT_DIR/post-deploy.sh" ]; then
    echo "post deploy script detected"
    chmod +x $CUSTOM_SCRIPT_DIR/post-deploy.sh
    GENERATE_DIR=${OUTPUT_DIR} BASE_TEMPLATE_DIR=${CUSTOM_SCRIPT_DIR} ${CUSTOM_SCRIPT_DIR}/post-deploy.sh
 elif [ -f "$CUSTOM_SCRIPT_DIR/post-bosh-deploy.sh" ]; then
    echo "**deprecated** LEGACY post bosh deploy script detected"
    echo "Please rename post-bosh-deploy.sh to post-deploy.sh to be compliant"
    chmod +x $CUSTOM_SCRIPT_DIR/post-bosh-deploy.sh
    GENERATE_DIR=${OUTPUT_DIR} BASE_TEMPLATE_DIR=${CUSTOM_SCRIPT_DIR} ${CUSTOM_SCRIPT_DIR}/post-bosh-deploy.sh
 else
    echo "ignoring post-deploy. No $CUSTOM_SCRIPT_DIR/post-deploy.sh or post-bosh-deploy.sh detected"
 fi
else
    echo "ignoring post-deploy. No $CUSTOM_SCRIPT_DIR/post-deploy.sh or post-bosh-deploy.sh detected"
fi
