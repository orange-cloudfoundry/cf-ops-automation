#!/bin/sh

spruce --version
CURRENT_DIR=$(pwd)
OUTPUT_DIR=${CURRENT_DIR}/generated-files/

SUFFIX=${SUFFIX:-"-tpl.yml"}
echo "selecting ${SUFFIX} in ${YML_TEMPLATE_DIR}"
for template in $(ls $YML_TEMPLATE_DIR/*$SUFFIX)
do
    filename=$(basename $template)
    file_extention=${SUFFIX#-tpl}
    echo "processing $filename"
    output_filename=${filename%$SUFFIX}${file_extention}
    echo "generating ${output_filename}"
    scripts-resource/scripts/manifest/spruce-manifest.sh $template ${YML_FILES} >${OUTPUT_DIR}/${output_filename}
done



