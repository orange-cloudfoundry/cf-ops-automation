#!/bin/bash
K8S_GIT_REPO_PATH=${K8S_GIT_REPO_PATH:-.}
BASE_TEMPLATE_DIR=${BASE_TEMPLATE_DIR:-.}
#set -x
#sample "manual deployment'
K8S_OUTPUT_DIR="$K8S_GIT_REPO_PATH/hello-world-root-depls/k8s-sample"
mkdir -p "$K8S_OUTPUT_DIR"

ytt -f "$BASE_TEMPLATE_DIR/config.yml" -f "$BASE_TEMPLATE_DIR/values.yml" --data-values-env COA > "$K8S_OUTPUT_DIR/ytt-interpolated.yml"

credhub interpolate -f "$K8S_OUTPUT_DIR/ytt-interpolated.yml" > "$K8S_OUTPUT_DIR/credhub-interpolated.yml"

#conf test: assert syntax level
