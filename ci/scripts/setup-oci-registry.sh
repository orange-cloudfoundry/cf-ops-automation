#!/bin/sh
set -e
#curl -sSL $OCI_REGISTRY_URL/api/v2.0/health|jq .

#$OCI_REGISTRY_URL/api/v2.0/registries?q=dockerhub-for-coa-ci
coa_ci_registry_name="dockerhub-for-coa-ci"
coa_ci_project_name="coa-ci.docker.io"


registry_id=$(curl -sSL -u "$OCI_REGISTRY_USERNAME:$OCI_REGISTRY_PASSWORD" -H 'Content-Type: application/json' \
  "$OCI_REGISTRY_URL/api/v2.0/registries?name=$coa_ci_registry_name"|jq -r 'first(.[]? | .id) // ""' )
if [ "$registry_id" = "" ];then
  echo "Creating registry $coa_ci_registry_name"
  curl -sSL -u "$OCI_REGISTRY_USERNAME:$OCI_REGISTRY_PASSWORD" -H 'Content-Type: application/json' \
    -X POST $OCI_REGISTRY_URL/api/v2.0/registries \
    -d '{ "name": "'$coa_ci_registry_name'", "url": "https://hub.docker.com", "type": "docker-hub", "insecure": false}'
  echo "registry $coa_ci_registry_name created. Getting id"
  registry_id=$(curl -sSL -u "$OCI_REGISTRY_USERNAME:$OCI_REGISTRY_PASSWORD" -H 'Content-Type: application/json' \
    "$OCI_REGISTRY_URL/api/v2.0/registries?name=$coa_ci_registry_name"|jq -r 'first(.[]? | .id) // ""' )
fi
if [ "$registry_id" = "" ];then
  echo "ERROR: failed to create registry"
  exit 1
fi

echo "Registry $coa_ci_registry_name id: $registry_id"

DATA=$(jq -n --arg name "$coa_ci_project_name" --argjson reg "$registry_id" '{project_name: $name, metadata: {public: "true"}, registry_id: $reg}')
if ! curl --head -sSLf -H 'accept: application/json' -u "$OCI_REGISTRY_USERNAME:$OCI_REGISTRY_PASSWORD" "$OCI_REGISTRY_URL/api/v2.0/projects?project_name=$coa_ci_project_name" 2>&1 >/dev/null;then
  echo "Project $coa_ci_project_name NOT FOUND"
  curl -u "$OCI_REGISTRY_USERNAME:$OCI_REGISTRY_PASSWORD" -H 'Content-Type: application/json' \
    -X POST $OCI_REGISTRY_URL/api/v2.0/projects \
    -d "$DATA"
else
  echo "Project $coa_ci_project_name already exists"
fi

if ! curl --head -sSLf -H 'accept: application/json' -u "$OCI_REGISTRY_USERNAME:$OCI_REGISTRY_PASSWORD" "$OCI_REGISTRY_URL/api/v2.0/projects?project_name=$coa_ci_project_name";then
  echo "FAILED to create project $coa_ci_project_name"
  exit 1
fi
