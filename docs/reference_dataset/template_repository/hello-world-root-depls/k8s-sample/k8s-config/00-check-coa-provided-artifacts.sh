#!/bin/bash
set -e
#paas-templates is cloned

#check COA prerequisite
ytt --version
kustomize version
credhub --version #credentials configured by COA

credhub set --type value --name "/credhub-set-test" --value "passed"
credhub delete --name "/credhub-set-test"

credhub set --type value --name "/coa-my-credhub-key" --value "This is my credhub value" # Used by 01-interpolate.sh and deleted in 02-deploy.sh

#for artifact push to k8s
kapp version
echo "Kubectl:"
kubectl version --client -o=yaml
echo "Helm: $(helm version --short)"

kuttl -v
git --version

#env var gives COA deployment name
if [ -z "$COA_DEPLOYMENT_NAME" ]; then
  echo "env COA_DEPLOYMENT_NAME is missing"
  exit 1
else
  echo "Deployment name: $COA_DEPLOYMENT_NAME"
fi

if [ -z "$IAAS_TYPE" ]; then
  echo "env IAAS_TYPE is missing"
  exit 1
else
  echo "Iaas type: $IAAS_TYPE"
fi

if [ -z "$PROFILES" ]; then
  echo "env PROFILES is missing"
  exit 1
else
  echo "Profiles: $PROFILES"
fi

if [ -z "$K8S_GIT_REPO_PATH" ]; then
  echo "env K8S_GIT_REPO_PATH is missing"
  exit 1
else
  echo "Git repository path: $GIT_REPO_PATH"
fi

if [ -z "$BASE_TEMPLATE_DIR" ]; then
  echo "env BASE_TEMPLATE_DIR is missing"
  exit 1
else
  echo "BASE_TEMPLATE_DIR: $BASE_TEMPLATE_DIR"
fi

if [ -z "$PAAS_TEMPLATES_COMMIT_ID" ]; then
  echo "env PAAS_TEMPLATES_COMMIT_ID is missing"
  exit 1
else
  echo "Git repository path: $PAAS_TEMPLATES_COMMIT_ID"
fi

if [ -z "$PAAS_TEMPLATES_COMMITTER" ]; then
  echo "env PAAS_TEMPLATES_COMMITTER is missing"
  exit 1
else
  echo "PAAS_TEMPLATES_COMMITTER: $PAAS_TEMPLATES_COMMITTER"
fi

if [ -z "$PAAS_TEMPLATES_COMMIT_MESSAGE" ]; then
  echo "env PAAS_TEMPLATES_COMMIT_MESSAGE is missing"
  exit 1
else
  echo "PAAS_TEMPLATES_COMMIT_MESSAGE: $PAAS_TEMPLATES_COMMIT_MESSAGE"
fi
