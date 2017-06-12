#!/bin/sh
set -e

CURRENT_DIR=$(pwd)
OUTPUT_DIR=${OUTPUT_DIR:-${CURRENT_DIR}/generated-files/}
COMMON_SCRIPT_DIR=${COMMON_SCRIPT_DIR:-scripts-resource/scripts/manifest}

${COMMON_SCRIPT_DIR}/generate-manifest.sh

if [ -n "$CUSTOM_SCRIPT_DIR" -a  -f "$CUSTOM_SCRIPT_DIR/post-generate.sh" ]
then
    echo "post generation script detected"
    chmod +x $CUSTOM_SCRIPT_DIR/post-generate.sh
    GENERATE_DIR=$OUTPUT_DIR BASE_TEMPLATE_DIR=$CUSTOM_SCRIPT_DIR $CUSTOM_SCRIPT_DIR/post-generate.sh
fi
