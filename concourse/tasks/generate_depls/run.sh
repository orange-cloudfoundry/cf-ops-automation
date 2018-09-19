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

env
if [ -z "${ROOT_DEPLOYMENT}" ]
then
    echo "ERROR: missing environment variable: ROOT_DEPLOYMENT" | tee -a result-dir/error.log
fi

if [ -z "${IAAS_TYPE}" ]
then
    echo "ERROR: missing environment variable: IAAS_TYPE" | tee -a result-dir/error.log
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
./scripts/generate-depls.rb --depls "${ROOT_DEPLOYMENT}" -t ../templates -p . -o concourse --iaas "${IAAS_TYPE}"| tee generate-depls.log
