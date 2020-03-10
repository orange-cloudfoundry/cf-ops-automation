#!/usr/bin/env bash

# CURRENT_SCRIPT_DIR=$(realpath "$0"|xargs dirname)
# PIPELINE_NAME="control-plane"
# ${CURRENT_SCRIPT_DIR}/load-static-pipeline.sh

echo "Please use bootstrap-all-init-pipeline to load control-plane, otherwise you will lose concourse team definition"
exit 1
