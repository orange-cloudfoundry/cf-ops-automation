#!/bin/sh

set -e

spruce --version
CURRENT_DIR=$(pwd)
OUTPUT_DIR=${OUTPUT_DIR:-${CURRENT_DIR}/generated-files/}
SPRUCE_SCRIPT_DIR=${SPRUCE_SCRIPT_DIR:-scripts-resource/scripts/manifest}

SUFFIX=${SUFFIX:-"-tpl.yml"}
echo "selecting ${SUFFIX} in ${YML_TEMPLATE_DIR}"
for template in $(ls $YML_TEMPLATE_DIR/*$SUFFIX)
do
    filename=$(basename $template)
    file_extention=${SUFFIX#-tpl}
    echo "processing $filename"
    output_filename=${filename%$SUFFIX}${file_extention}
    echo "generating ${output_filename}"
     ${SPRUCE_SCRIPT_DIR}/spruce-manifest.sh $template ${YML_FILES} >${OUTPUT_DIR}/${output_filename}
done



