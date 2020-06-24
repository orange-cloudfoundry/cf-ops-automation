#!/usr/bin/env bash
set -e

LOCAL_DIR=$(dirname $0)
"${LOCAL_DIR}/../scripts/generate-depls.rb" --depls hello-world-root-depls \
    -p ../docs/reference_dataset/config_repository \
    -t ../docs/reference_dataset/template_repository \
    -a .. \
    --profiles vault-profile \
    -o ../bootstrap-generated/ \
    --iaas openstack
