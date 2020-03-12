#!/bin/sh
set -e

CURRENT_DIR=$(pwd)
OUTPUT_DIR=${OUTPUT_DIR:-${CURRENT_DIR}/generated-files/}
COMMON_SCRIPT_DIR=${COMMON_SCRIPT_DIR:-scripts-resource/concourse/tasks/generate_manifest}

process_bosh_config_files() {
    for config_file in cloud-config.yml runtime-config.yml cpi-config.yml; do
        if [ -e ${config_file} ]; then
            echo "copying '${YML_TEMPLATE_DIR}/${config_file}' to '${OUTPUT_DIR}'"
            cp "${config_file}" "${OUTPUT_DIR}"
        fi
    done
}

generate_manifest() {
    local customization_dir=$1
    local yml_template_dir=$2
    local output_dir=$3
    local common_script_dir=$4

    if [ -n "${customization_dir}" -a  -d "${yml_template_dir}/${customization_dir}" ]; then
        echo "Customization detected for ${customization_dir}"
        find "${yml_template_dir}"/"${customization_dir}" -maxdepth 1 -name "*-operators.yml" -exec cp --verbose {} "${output_dir}" +
        find "${yml_template_dir}"/"${customization_dir}" -maxdepth 1 -name "*-vars.yml" -exec cp --verbose {} "${output_dir}" +
        YML_TEMPLATE_DIR=${yml_template_dir}/${customization_dir} ${common_script_dir}/generate-manifest.sh
        exit_code=$?
        if [ ${exit_code} -ne 0 ]; then
            echo "Error detected - exit code: $exit_code"
            exit ${exit_code}
        fi
    else
        return 3
    fi
}

cd "${YML_TEMPLATE_DIR}"

process_bosh_config_files
echo "Coping operators files from '${YML_TEMPLATE_DIR}' to '${OUTPUT_DIR}'"
find . -maxdepth 1 -name "*-operators.yml" -exec cp --verbose {} "${OUTPUT_DIR}" +

echo "Coping vars files from '${YML_TEMPLATE_DIR}' to '${OUTPUT_DIR}'"
find . -maxdepth 1 -name "*-vars.yml" -exec cp --verbose {} "${OUTPUT_DIR}" +
cd "${CURRENT_DIR}"

${COMMON_SCRIPT_DIR}/generate-manifest.sh

set +e
generate_manifest "${IAAS_TYPE}" "${YML_TEMPLATE_DIR}" "${OUTPUT_DIR}" "${COMMON_SCRIPT_DIR}"
if [ $? -eq 3 ]; then
    echo "ignoring Iaas customization. IAAS_TYPE not defined set or ${YML_TEMPLATE_DIR}/<IAAS_TYPE> detected. Tag: <${IAAS_TYPE}>"
fi

echo "${PROFILES}"|sed -e 's/,/\n/g' > /tmp/profiles.txt
if [ "$PROFILES_AUTOSORT" = "true" ]; then
    NEWLINE_DELIMITED_PROFILES=$(sort </tmp/profiles.txt)
    echo -e "Auto sort profiles:\n${NEWLINE_DELIMITED_PROFILES}"
else
    NEWLINE_DELIMITED_PROFILES=$(cat /tmp/profiles.txt)
    echo "Auto sort profiles disabled: ${NEWLINE_DELIMITED_PROFILES}"
fi
for profile in ${NEWLINE_DELIMITED_PROFILES}; do
    echo "-------------------------"
    generate_manifest "${profile}" "${YML_TEMPLATE_DIR}" "${OUTPUT_DIR}" "${COMMON_SCRIPT_DIR}"
    if [ $? -eq 3 ]; then
        echo "ignoring ${profile} customization. Profile not defined set or ${YML_TEMPLATE_DIR}/<PROFILE> detected. Tag: <${profile}>"
    fi
done
set -e

if [ -n "$CUSTOM_SCRIPT_DIR" ] && [ -f "$CUSTOM_SCRIPT_DIR/post-generate.sh" ]; then
    echo "post generation script detected"
    chmod +x ${CUSTOM_SCRIPT_DIR}/post-generate.sh
    GENERATE_DIR="${OUTPUT_DIR}" BASE_TEMPLATE_DIR="${CUSTOM_SCRIPT_DIR}" ${CUSTOM_SCRIPT_DIR}/post-generate.sh
else
    echo "ignoring post generate. No $CUSTOM_SCRIPT_DIR/post-generate.sh detected"
fi
