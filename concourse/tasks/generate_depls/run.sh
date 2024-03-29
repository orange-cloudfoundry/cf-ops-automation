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
set -C
set -o pipefail # error on first command failure when using pipe

DEBUG_OPTIONS="--no-dump"
if [ "${DEBUG}" = "true" ]
then
   echo "INFO: Enabling debug options: dump pipelines"
   DEBUG_OPTIONS="--dump"
else
    echo "INFO: debug mode disabled"
fi


if [ -n "${PROFILES}" ]
then
   echo "Profiles detected: ${PROFILES}"
   PROFILES_OPTION="--profiles ${PROFILES}"
else
   echo "INFO: undefined variable: PROFILES - ignoring"
fi

if [ -n "${EXCLUDE_PIPELINES}" ]
then
   echo "Excluding pipeline templates matching ${EXCLUDE_PIPELINES}"
   PIPELINES_RESTRICTIONS="--exclude ${EXCLUDE_PIPELINES}"
else
    echo "INFO: undefined variable: EXCLUDE_PIPELINES - ignoring"
fi

if [ -z "${ROOT_DEPLOYMENT}" ]
then
    echo "ERROR: missing environment variable: ROOT_DEPLOYMENT" | tee -a result-dir/error.log
fi

if [ -z "${IAAS_TYPE}" ]
then
    echo "ERROR: missing environment variable: IAAS_TYPE" | tee -a result-dir/error.log
else
    echo "Selected Iaas Type: <${IAAS_TYPE}>"
fi

if [ -s "result-dir/error.log" ]
then
    echo "errors detected - exiting"
    exit 1
fi


cp -r templates/. result-dir
cp -r scripts-resource/. result-dir
cp -rf secrets/. result-dir
cd result-dir
./scripts/generate-depls.rb --depls "${ROOT_DEPLOYMENT}" -t ../templates -p . -o concourse ${DEBUG_OPTIONS} --iaas "${IAAS_TYPE}" ${PROFILES_OPTION} ${PIPELINES_RESTRICTIONS} > >(tee generate-depls.log) 2> >(tee -a error.log >&2) # tee generate-depls.log
if [ -s 'error.log' ]; then
    cat error.log
    exit 1
fi