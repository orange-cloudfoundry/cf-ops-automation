#!/usr/bin/env bash
#
# Copyright (C) 2015-2020 Orange
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -eC
echo "Credhub info:"
credhub --version
echo "Bosh CLI info: $(bosh --version)"

ls -lrt config-manifest
VARS_FILES_SUFFIX=${VARS_FILES_SUFFIX:-$CONFIG_TYPE-vars.yml}
OPS_FILES_SUFFIX=${OPS_FILES_SUFFIX:-$CONFIG_TYPE-operators.yml}
VARS_FILES=""
OPS_FILES=""
if [[ "$CONFIG_TYPE" = "" ]];then
    echo "ERROR: Config type must be provided. Config type, e.g. 'cloud', 'runtime', or 'cpi' "
    exit 1
else
    echo "Config type detected: $CONFIG_TYPE"
fi

echo "selecting vars files with '${VARS_FILES_SUFFIX}' suffix"
for a_vars_file in $(ls ./config-manifest/*${VARS_FILES_SUFFIX}); do
    VARS_FILES="${VARS_FILES} -l ${a_vars_file}"
done

echo "selecting ops files with '${OPS_FILES_SUFFIX}' suffix"
for an_ops_file in $(ls ./config-manifest/*${OPS_FILES_SUFFIX}); do
    OPS_FILES="${OPS_FILES} -o ${an_ops_file}"
done

echo "Operators detected: <${OPS_FILES}>"
echo "Vars files detected: <${VARS_FILES}>"

source ./scripts-resource/scripts/bosh_cli_v2_login.sh "${BOSH_TARGET}"
cat "config-manifest/${CONFIG_TYPE}-config.yml"
OLD_CONFIG=$(mktemp "${CONFIG_TYPE}-config-XXXXXX")
echo "getting current ${CONFIG_TYPE}-config"
bosh "${CONFIG_TYPE}-config" >>"${OLD_CONFIG}" || true

echo "diff between current ${CONFIG_TYPE}-config and to be deployed version"
diff "${OLD_CONFIG}" "config-manifest/${CONFIG_TYPE}-config.yml" || true

echo "apply operators and vars files to ${CONFIG_TYPE}-config.yml"
BOSH_INTERPOLATED_FILE="bosh-interpolated-${CONFIG_TYPE}-config.yml"
bosh -n int ${VARS_FILES} ${OPS_FILES} "config-manifest/${CONFIG_TYPE}-config.yml" > "${BOSH_INTERPOLATED_FILE}"
cat "${BOSH_INTERPOLATED_FILE}"

echo "apply credhub interpolation to bosh interpolated file"
CREDHUB_INTERPOLATED_FILE="credhub-interpolated-${CONFIG_TYPE}-config.yml"
credhub interpolate -f "${BOSH_INTERPOLATED_FILE}" > "${CREDHUB_INTERPOLATED_FILE}"

bosh -n update-config --type "${CONFIG_TYPE}" "${CREDHUB_INTERPOLATED_FILE}"
bosh -n "${CONFIG_TYPE}-config" > "deployed-config/${CONFIG_TYPE}-config.yml"
