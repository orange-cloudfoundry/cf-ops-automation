#!/usr/bin/env bash
#
# Copyright (C) 2015-2018 Orange
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


if [ -z "${BOSH_TARGET}" ]
then
    echo "ERROR: missing environment variable: BOSH_TARGET" | tee -a delete-result-dir/error.log
fi

if [ -z "${BOSH_CLIENT}" ]
then
    echo "ERROR: missing environment variable: BOSH_CLIENT" | tee -a delete-result-dir/error.log
fi

if [ -z "${BOSH_CLIENT_SECRET}" ]
then
    echo "ERROR: missing environment variable: BOSH_CLIENT_SECRET" | tee -a delete-result-dir/error.log
fi

if [ -z "${BOSH_CA_CERT}" ]
then
    echo "ERROR: missing environment variable: BOSH_CA_CERT" | tee -a delete-result-dir/error.log
fi

if [ -z "${DEPLOYMENTS_TO_DELETE}" ]
then
    echo "ERROR: missing environment variable: DEPLOYMENTS_TO_DELETE" | tee -a delete-result-dir/error.log
fi

if [ -s "result-dir/error.log" ]
then
    echo "errors detected - exiting"
    ls -l result-dir/error.log
    exit 1
fi

# shellcheck disable=SC1091
# we disable this check as the path below is only available in concourse task
source ./scripts-resource/scripts/bosh_cli_v2_login.sh "${BOSH_TARGET}"
for DEPLOYMENT_NAME in $(printf "%s" "${DEPLOYMENTS_TO_DELETE}"); do
  echo "Deleting deployment ${DEPLOYMENT_NAME} if exists"
  bosh -n --deployment="${DEPLOYMENT_NAME}" delete-deployment
done
