#!/bin/bash
readonly base_dir_dir="$(realpath $0|xargs dirname)"
GIT_REPO="$base_dir_dir"
LOG_LEVEL="${LOG_LEVEL:-debug}"
RENOVATE_ENABLED_MANAGERS="${RENOVATE_ENABLED_MANAGERS:-""}"
RENOVATE_INCLUDE_PATHS="${RENOVATE_INCLUDE_PATHS:-""}"
if [ -z "$GITHUB_COM_TOKEN" ];then
  echo -e "WARNING: missing GitHub token to allow. Please set it before running this script, using \n export GITHUB_COM_TOKEN=\"xxx\""
  sleep 1
fi
echo "Log level: $LOG_LEVEL"
echo "RENOVATE_ENABLED_MANAGERS: $RENOVATE_ENABLED_MANAGERS #Empty means all managers enabled"
echo "RENOVATE_INCLUDE_PATHS: $RENOVATE_INCLUDE_PATHS #Empty means scan all paths"
echo "Git repo volume path: $GIT_REPO"
docker run \
    --rm \
    -e LOG_LEVEL="$LOG_LEVEL" \
    -e GITHUB_COM_TOKEN="$GITHUB_COM_TOKEN" \
    -e RENOVATE_ENABLED_MANAGERS="$RENOVATE_ENABLED_MANAGERS" \
    -e RENOVATE_INCLUDE_PATHS="$RENOVATE_INCLUDE_PATHS" \
    -v "$GIT_REPO:/tmp/local-git-repo" \
    --workdir /tmp/local-git-repo \
    ghcr.io/renovatebot/renovate \
    --platform=local \
    --semantic-commits=disabled \
    | tee -a renovate.log
#    --dry-run="true" \
