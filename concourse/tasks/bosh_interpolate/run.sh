#!/usr/bin/env bash
#
# Copyright (C) 2015-2017 Orange
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
ls -lrt bosh-inputs

VARS_FILES=""
OPS_FILES=""

if [ -z "$BOSH_YAML_FILE" ]
then
    echo "ERROR: missing environment variable: BOSH_YAML_FILE" | tee result-dir/error.log
    exit 1
fi

for a_vars_file in $(ls ./bosh-inputs/*${VARS_FILES_SUFFIX}); do
    VARS_FILES="${VARS_FILES} -l ${a_vars_file}"
done

for an_ops_file in $(ls ./bosh-inputs/*${OPS_FILES_SUFFIX}); do
    OPS_FILES="${OPS_FILES} -o ${an_ops_file}"
done

echo "Operators detected: <${OPS_FILES}>"
echo "Vars files detected: <${VARS_FILES}>"

INTERPOLATED_FILE="interpolated-${BOSH_YAML_FILE}"
bosh -n int ${VARS_FILES} ${OPS_FILES} "manifest-dir/${BOSH_YAML_FILE}" > "result-dir/${INTERPOLATED_FILE}"

echo "Generated manifest ${INTERPOLATED_FILE} (from ${BOSH_YAML_FILE}):"
cat "result-dir/${INTERPOLATED_FILE}"
