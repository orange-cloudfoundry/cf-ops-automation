#!/bin/sh

CURRENT_DIR=$(pwd)
OUTPUT_DIR=${OUTPUT_DIR:-${CURRENT_DIR}/generated-files/}
COMMON_SCRIPT_DIR=${COMMON_SCRIPT_DIR:-scripts-resource/scripts/manifest}


cp -r additional-resource/. $OUTPUT_DIR

if [ -n "$CUSTOM_SCRIPT_DIR" -a  -f "$CUSTOM_SCRIPT_DIR/pre-bosh-deploy.sh" ]
then
    echo "pre bosh deploy script detected"
    GENERATE_DIR=$OUTPUT_DIR BASE_TEMPLATE_DIR=$CUSTOM_SCRIPT_DIR $CUSTOM_SCRIPT_DIR/pre-bosh-deploy.sh
fi
