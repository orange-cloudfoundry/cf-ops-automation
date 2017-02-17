#!/bin/sh

spruce --version
CURRENT_DIR=$(pwd)
OUTPUT_DIR=${CURRENT_DIR}/generated-files/

SUFFIX=-tpl.yml
for template in $(ls $YML_TEMPLATE_DIR/*$SUFFIX)
do
    filename=$(basename $template)
    echo "Processing $filename"
    output_filename=${filename%$SUFFIX}.yml
    scripts-resource/scripts/manifest/spruce-manifest.sh $template ${YML_FILES} >${OUTPUT_DIR}/${output_filename}
done



