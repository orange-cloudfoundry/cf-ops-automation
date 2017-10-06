#!/bin/sh
set -e

CURRENT_DIR=$(pwd)
OUTPUT_DIR=${OUTPUT_DIR:-${CURRENT_DIR}/generated-files/}
COMMON_SCRIPT_DIR=${COMMON_SCRIPT_DIR:-scripts-resource/scripts/manifest}

echo "Coping operators files from '${YML_TEMPLATE_DIR}' to '${OUTPUT_DIR}'"
find ${YML_TEMPLATE_DIR} -maxdepth 1 -name "*-operators.yml" -exec cp --verbose {} ${OUTPUT_DIR} \;

${COMMON_SCRIPT_DIR}/generate-manifest.sh

if [ -n "$CUSTOM_SCRIPT_DIR" -a  -f "$CUSTOM_SCRIPT_DIR/post-generate.sh" ]
then
    echo "post generation script detected"
    chmod +x ${CUSTOM_SCRIPT_DIR}/post-generate.sh
    GENERATE_DIR=${OUTPUT_DIR} BASE_TEMPLATE_DIR=${CUSTOM_SCRIPT_DIR} ${CUSTOM_SCRIPT_DIR}/post-generate.sh
else
    echo "ignoring post generate. No $CUSTOM_SCRIPT_DIR/post-generate.sh detected"

fi
