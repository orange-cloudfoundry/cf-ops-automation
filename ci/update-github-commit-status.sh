#!/bin/bash
OWNER=${OWNER:-orange-cloudfoundry}
REPO=${REPO:-cf-ops-automation}

PR_STATUS="error"
CONTEXT="concourse-ci/status"
CI_URL=""
usage(){
 echo "$0 -c <commit_sha1> [-s <PR-Status>] [-c <Context>] [-i <CI_URL>]"
 echo "  -c|--commit: commit_sha1"
 echo "  -s|--status: status to set. Default: $PR_STATUS"
 echo "  -x|--context: context to set. Default: $CONTEXT"
 echo "  -i|--ci-url: context to set. Default: $CI_URL"
 exit 1
}


while [ "$#" -gt 0 ] ; do
  case "$1" in
    "-c"|"--commit")
      REF="$2"
      shift ; shift ;;
    "-s"|"--status")
        PR_STATUS="$2"
        shift ; shift ;;
    "-i"|"--ci-url")
        CI_URL="$2"
        shift ; shift ;;
    "-x"|"--context")
        CONTEXT="$2"
        shift ; shift ;;
    *) usage ;;
  esac
done

if [ "${REF}" = "" ] ; then
  usage
fi
case $PR_STATUS in
error|pending|failure|success)
  echo "Status ($PR_STATUS) is valid"
  ;;
*)
  echo "ERROR: invalid status: $PR_STATUS. Valid status are: error|pending|failure|success"
  exit 1
esac

gh api --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/$OWNER/$REPO/statuses/$REF \
  -f state="$PR_STATUS" \
  -f description="CI update ($REF) - Set to $PR_STATUS" \
  -f target_url="$CI_URL" \
  -f context=$CONTEXT

