#!/bin/sh

CURRENT_DIR=$(pwd)
OUTPUT_DIR=${OUTPUT_DIR:-${CURRENT_DIR}/generated-files/}
COMMON_SCRIPT_DIR=${COMMON_SCRIPT_DIR:-scripts-resource/scripts/manifest}


if [ -n "$CUSTOM_SCRIPT_DIR" -a  -f "$CUSTOM_SCRIPT_DIR/pre-bosh-deploy.sh" ]
then
    cp -r additional-resource/. $OUTPUT_DIR
    echo "pre bosh deploy script detected"
    GENERATE_DIR=$OUTPUT_DIR BASE_TEMPLATE_DIR=$CUSTOM_SCRIPT_DIR $CUSTOM_SCRIPT_DIR/pre-bosh-deploy.sh
fi
