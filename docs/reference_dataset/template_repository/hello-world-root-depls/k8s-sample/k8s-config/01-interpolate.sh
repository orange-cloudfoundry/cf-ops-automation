#!/bin/bash
K8S_GIT_REPO_PATH=${K8S_GIT_REPO_PATH:-.}
BASE_TEMPLATE_DIR=${BASE_TEMPLATE_DIR:-.}
#set -x
set -e # We choose in each script how we handle errors
#sample "manual deployment'
K8S_OUTPUT_DIR="$K8S_GIT_REPO_PATH/hello-world-root-depls/k8s-sample"
mkdir -p "$K8S_OUTPUT_DIR"

echo "$BASE_TEMPLATE_DIR content: $(ls "$BASE_TEMPLATE_DIR") \# <- This directory contains applied profiles and current iaas type"

if [ -f "$BASE_TEMPLATE_DIR"/values-iaas-type.yml ];then
  echo "Iaas type values available"
else
  echo "ERROR: missing values-iaas-type.yml - '$BASE_TEMPLATE_DIR'/values-iaas-type.yml"
  exit 1
fi

if [ -f "$BASE_TEMPLATE_DIR"/values-profile.yml ];then
  echo "Values values available"
else
  echo "ERROR: missing values-profile - '$BASE_TEMPLATE_DIR'/values-profile.yml"
  exit 1
fi

ytt -f "$BASE_TEMPLATE_DIR"/config.yml -f "$BASE_TEMPLATE_DIR"/values.yml --data-values-env COA > "$K8S_OUTPUT_DIR"/ytt-interpolated.yml
if [ ! -s "$K8S_OUTPUT_DIR"/ytt-interpolated.yml ]; then
  echo "ERROR $K8S_OUTPUT_DIR/ytt-interpolated.yml is empty"
  exit 1
fi

TIMESTAMP=$(date +'%Y-%m-%d-%H-%M-%S')

credhub interpolate -f "$K8S_OUTPUT_DIR"/ytt-interpolated.yml > "$K8S_OUTPUT_DIR"/"credhub-interpolated-${TIMESTAMP}".yml

#conf test: assert syntax level
