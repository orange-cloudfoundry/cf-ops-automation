#!/bin/bash

echo "Available tools:"
for app in /usr/local/bin/*; do
  echo "$app: $($app --version 2>/dev/null|| $app version 2>/dev/null)"
done

if [ -z "$CUSTOM_SCRIPT_DIR" ];then
  echo "ERROR: environment variable CUSTOM_SCRIPT_DIR is missing. Please set it."
  exit 1
fi

echo '---------------------'
OUTPUT_DIR=$(realpath "${OUTPUT_DIR:-result-dir}")
if [ -z "$CREDHUB_CA_CERT" ]; then
  echo "WARNING: CREDHUB_CA_CERT is empty"
else
  CREDHUB_CA_CERT=$(realpath "${CREDHUB_CA_CERT}")
  export CREDHUB_CA_CERT
fi
PRE_PROCESSED_MANIFEST_PATH=$(realpath pre-processed-manifest||"")
export PRE_PROCESSED_MANIFEST_PATH

K8S_GIT_REPO_PATH="${OUTPUT_DIR}"
export K8S_GIT_REPO_PATH

if [ -d "${CUSTOM_SCRIPT_DIR}" ]; then
  BASE_TEMPLATE_DIR=$(realpath "${CUSTOM_SCRIPT_DIR}")
  export BASE_TEMPLATE_DIR
else
  BASE_TEMPLATE_DIR="${CUSTOM_SCRIPT_DIR}"
  export BASE_TEMPLATE_DIR
fi

PAAS_TEMPLATES_COMMIT_ID=$(cat  paas-templates-resource/.git/ref)
export PAAS_TEMPLATES_COMMIT_ID
PAAS_TEMPLATES_COMMITTER=$(cat  paas-templates-resource/.git/committer)
export PAAS_TEMPLATES_COMMITTER
PAAS_TEMPLATES_COMMIT_MESSAGE=$(cat  paas-templates-resource/.git/commit_message)
export PAAS_TEMPLATES_COMMIT_MESSAGE
echo "Available Env Var:"
echo "\$COA_ROOT_DEPLOYMENT_NAME: root deployment name (set to: $COA_ROOT_DEPLOYMENT_NAME)"
echo "\$COA_DEPLOYMENT_NAME: deployment name (set to: $COA_DEPLOYMENT_NAME)"
echo "\$BASE_TEMPLATE_DIR: directory containing k8s scripts to execute (set to: $BASE_TEMPLATE_DIR)"
echo "\$K8S_GIT_REPO_PATH: directory containing generated files (set to: $K8S_GIT_REPO_PATH)"
echo "\$PAAS_TEMPLATES_COMMIT_ID, \$PAAS_TEMPLATES_COMMITTER, \$PAAS_TEMPLATES_COMMIT_MESSAGE"
echo "\$PRE_PROCESSED_MANIFEST_PATH: directory containing files processed during 'generate-<deployment-name>-manifest' step"
echo '---------------------'

if [ -z "$PAAS_TEMPLATES_COMMIT_ID" ]; then
  echo "WARNING: PAAS_TEMPLATES_COMMIT_ID is empty"
fi
if [ -z "$PAAS_TEMPLATES_COMMITTER" ]; then
  echo "WARNING: PAAS_TEMPLATES_COMMITTER is empty"
fi
if [ -z "$PAAS_TEMPLATES_COMMIT_MESSAGE" ]; then
  echo "WARNING: PAAS_TEMPLATES_COMMIT_MESSAGE is empty"
fi

echo "setup OUTPUT K8S_GIT_REPO_PATH"
git config --global advice.detachedHead false
git config --global user.email "$GIT_USER_EMAIL"
git config --global user.name "$GIT_USER_NAME"

set -e

git clone k8s-configs-repository "${OUTPUT_DIR}/"

if [ -d "$PRE_PROCESSED_MANIFEST_PATH" ]; then
  echo "list pre-proccessed files ($PRE_PROCESSED_MANIFEST_PATH):"
  pushd "$PRE_PROCESSED_MANIFEST_PATH"
  du -a .
  popd
else
  echo "INFO: PRE_PROCESSED_MANIFEST_PATH is not used"
fi
set +e
if [ -n "$BASE_TEMPLATE_DIR" ]; then
  k8s_scripts_count=$(find "$BASE_TEMPLATE_DIR" -name "${FILE_EXECUTION_FILTER}"|wc -l)
  if [ ${k8s_scripts_count} -gt 0 ]; then
    chmod +x "$BASE_TEMPLATE_DIR"/*.sh
    status=0
    for k8s_script in "$BASE_TEMPLATE_DIR"/${FILE_EXECUTION_FILTER};do
      echo "Processing $k8s_script"
      echo "______________________"
      set -e
      ${k8s_script}
      result=$?
      set +e
      status=$((status + result))

    done
    if [ $status -gt 0 ]; then
      echo "Error detected"
      exit $status
    fi
  else
    echo "ignoring k8s scripts. No scripts matching $BASE_TEMPLATE_DIR/${FILE_EXECUTION_FILTER}"
  fi
else
  echo "ignoring k8s scripts. No directory ($BASE_TEMPLATE_DIR) detected"
fi
