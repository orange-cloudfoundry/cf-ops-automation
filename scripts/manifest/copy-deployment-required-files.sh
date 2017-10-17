#!/bin/sh

set -ex

CURRENT_DIR=$(pwd)
OUTPUT_DIR=${OUTPUT_DIR:-${CURRENT_DIR}/generated-files}
COMMON_SCRIPT_DIR=${COMMON_SCRIPT_DIR:-scripts-resource/scripts/manifest}

echo "copying additional resources"
cp -r additional-resource/. ${OUTPUT_DIR}/

echo "checking manifest '${MANIFEST_NAME}' existence"
if [ -n "$OUTPUT_DIR" -a  ! -f "$OUTPUT_DIR/${MANIFEST_NAME}" ]
then
    if [ -n "$CUSTOM_SCRIPT_DIR" -a  -f "${CUSTOM_SCRIPT_DIR}/${MANIFEST_NAME}" ]
    then
        echo "default '${MANIFEST_NAME}' detected."
        cp ${CUSTOM_SCRIPT_DIR}/${MANIFEST_NAME} ${OUTPUT_DIR}/
    else
        echo "ignoring '${MANIFEST_NAME}'. No manifest detected."
    fi
else
    echo "'${MANIFEST_NAME}' already exists in additional-resource. Skipping copy !!!"
fi
