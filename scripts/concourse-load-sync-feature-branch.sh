#!/usr/bin/env bash
set -x
CURRENT_SCRIPT_DIR=$(realpath $0|xargs dirname)

${CURRENT_SCRIPT_DIR}/load-static-pipeline.sh