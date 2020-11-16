#!/bin/bash
set -e # We choose in each script how we handle errors

credhub delete --name "/coa-my-credhub-key"

#kapp deploy ./credhub-interpolated.yml
#kubectl apply ./credhub-interpolated.yml

pushd $K8S_GIT_REPO_PATH

echo "Add all changes to git"
git add --all
echo "Commit changes"
git commit -m"Commit from paas-templates: $PAAS_TEMPLATES_COMMIT_ID by  $PAAS_TEMPLATES_COMMITTER: $PAAS_TEMPLATES_COMMIT_MESSAGE"
popd
#helm install xxx

echo "Push is automatically done by COA"

