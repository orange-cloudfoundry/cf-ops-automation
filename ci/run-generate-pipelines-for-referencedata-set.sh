#!/bin/bash
set -e

PIPELINE_FILTERS_OPTION=""
if [ -n "${PIPELINE_FILTERS}" ]; then
  PIPELINE_FILTERS_OPTION="-i ${PIPELINE_FILTERS}"
fi

LOCAL_DIR=$(dirname $0)
"${LOCAL_DIR}/../scripts/generate-depls.rb" --depls hello-world-root-depls \
    -p ../docs/reference_dataset/config_repository \
    -t ../docs/reference_dataset/template_repository \
    -a .. \
    --profiles vault-profile \
    -o ../bootstrap-generated/ \
    --iaas openstack ${PIPELINE_FILTERS_OPTION}
