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
ls -lrt config-manifest

VARS_FILES=""
OPS_FILES=""

for a_vars_file in $(ls ./config-manifest/*${VARS_FILES_SUFFIX}); do
    VARS_FILES="${VARS_FILES} -l ${a_vars_file}"
done

for an_ops_file in $(ls ./config-manifest/*${OPS_FILES_SUFFIX}); do
    OPS_FILES="${OPS_FILES} -o ${an_ops_file}"
done

echo "Operators detected: <${OPS_FILES}>"
echo "Vars files detected: <${VARS_FILES}>"

source ./scripts-resource/scripts/bosh_cli_v2_login.sh ${BOSH_TARGET}
cat config-manifest/cloud-config.yml
OLD_CONFIG=$(mktemp cloud-config-XXXXXX)
bosh cloud-config >$OLD_CONFIG || true
diff $OLD_CONFIG config-manifest/cloud-config.yml || true

bosh -n int ${VARS_FILES} ${OPS_FILES} config-manifest/cloud-config.yml

bosh -n update-cloud-config ${VARS_FILES} ${OPS_FILES} config-manifest/cloud-config.yml

