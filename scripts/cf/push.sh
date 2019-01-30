#!/bin/sh

set -e
set -o pipefail

validate(){
    FAILURE=0
    if [ -z "$CF_API_URL" ]
    then
        echo "missing CF_API_URL"
        FAILURE=$((1 + $FAILURE))
    fi

    if [ -z "$CF_USERNAME" ]
    then
        echo "missing CF_USERNAME"
        FAILURE=$((2 + $FAILURE))
    fi

    if [ -z "$CF_PASSWORD" ]
    then
        echo "missing CF_PASSWORD"
        FAILURE=$((4 + $FAILURE))
    fi

    if [ ${FAILURE} -ne 0 ]
    then
        exit ${FAILURE}
    fi
}

#validate

CURRENT_DIR=$(pwd)
OUTPUT_DIR=${OUTPUT_DIR:-${CURRENT_DIR}/generated-files}
COMMON_SCRIPT_DIR=${COMMON_SCRIPT_DIR:-scripts-resource/scripts/cf}
ADDITIONAL_RESSOURCE=${ADDITIONAL_RESSOURCE:-additional-resource}

CF_MANIFEST=${CF_MANIFEST:-manifest.yml}

API_OPTIONS="--skip-ssl-validation"

echo "copying file from $ADDITIONAL_RESSOURCE to $OUTPUT_DIR"
cp -r "${ADDITIONAL_RESSOURCE}/." "${OUTPUT_DIR}/"

VARS_FILES=""
ls "${OUTPUT_DIR}/*"
for a_vars_file in $(ls "${OUTPUT_DIR}/*${VARS_FILES_SUFFIX}"); do
    VARS_FILES="${VARS_FILES} --vars-file ${a_vars_file}"
done

echo "Vars files detected: <${VARS_FILES}>"


#TODO add an option to manage ssl validation
cf --version
cf api "$CF_API_URL" $API_OPTIONS
cf auth "$CF_USERNAME" "$CF_PASSWORD"


if [ -n "$CUSTOM_SCRIPT_DIR" -a  -f "$CUSTOM_SCRIPT_DIR/pre-cf-push.sh" ]
then
    echo "pre CF push script detected"
    chmod +x ${CUSTOM_SCRIPT_DIR}/pre-cf-push.sh
    GENERATE_DIR="${OUTPUT_DIR}" BASE_TEMPLATE_DIR="${CUSTOM_SCRIPT_DIR}" "${CUSTOM_SCRIPT_DIR}/pre-cf-push.sh"
else
    echo "ignoring pre CF push. No $CUSTOM_SCRIPT_DIR/pre-cf-push.sh detected"
fi

VARS_FILES=""
for a_vars_file in $(ls "./${OUTPUT_DIR}/*${VARS_FILES_SUFFIX}"); do
    VARS_FILES="${VARS_FILES} --vars-file ${a_vars_file}"
done

echo "Vars files detected: <${VARS_FILES}>"


cf target -o "$CF_ORG" -s "$CF_SPACE"

set +e
# we need VARS_FILES to be expanded with spaces
# shellcheck disable=SC2086
cf push -f "${CF_MANIFEST}" ${VARS_FILES}|tee /tmp/cf-push.log
ret_code=$?
if [ ${ret_code} -ne 0 ]
then
    DISPLAY_LOG_CMD=$(grep "TIP: use 'cf logs" /tmp/cf-push.log |cut -d\' -f2)
    eval ${DISPLAY_LOG_CMD}
    exit ${ret_code}
fi
