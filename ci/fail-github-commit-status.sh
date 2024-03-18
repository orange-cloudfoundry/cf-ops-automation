#!/bin/bash
OWNER=${OWNER:-orange-cloudfoundry}
REPO=${REPO:-cf-ops-automation}

usage(){
 echo "$0 <commit_sha1>"
   commit_sha1
 exit 1
}

if [ $# -ne 1 ];then
  usage
fi

gh api --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/$OWNER/$REPO/statuses/$REF \
  -f state='error' \
  -f description='Manual update! Set to failure' \
  -f context='concourse-ci/status'
