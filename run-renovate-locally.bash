#!/bin/bash
readonly base_dir_dir="$(realpath $0|xargs dirname)"
GIT_REPO="$base_dir_dir"
LOG_LEVEL="${LOG_LEVEL:-debug}"
RENOVATE_ENABLED_MANAGERS="${RENOVATE_ENABLED_MANAGERS:-""}"
RENOVATE_INCLUDE_PATHS="${RENOVATE_INCLUDE_PATHS:-""}"
if [ -z "$GITHUB_COM_TOKEN" ];then
  echo -e "WARNING: missing GitHub token to allow github release version detection. Please set it before running this script, using \n export GITHUB_COM_TOKEN=\"xxx\""
  sleep 1
fi
if [ -z "$RENOVATE_BOT" ];then
  echo -e "WARNING: missing Renovate Bot. Please set it before running this script, using \n export RENOVATE_BOT=\"xxx\""
  sleep 1
fi
echo "Set LOG_LEVEL to manage log level. Default 'debug'.Current Log level: <$LOG_LEVEL>"
echo "Set RENOVATE_ENABLED_MANAGERS to restrict active managers. Current RENOVATE_ENABLED_MANAGERS: <$RENOVATE_ENABLED_MANAGERS> #Empty means all managers are enabled"
echo "Set RENOVATE_INCLUDE_PATHS to restrict renovate scan. Current RENOVATE_INCLUDE_PATHS: <$RENOVATE_INCLUDE_PATHS> #Empty means scan all paths"
echo "Git repo volume path: $GIT_REPO"
docker run \
    --rm \
    -e LOG_LEVEL="$LOG_LEVEL" \
    -e GITHUB_COM_TOKEN="$GITHUB_COM_TOKEN" \
    -e RENOVATE_ENABLED_MANAGERS="$RENOVATE_ENABLED_MANAGERS" \
    -e RENOVATE_INCLUDE_PATHS="$RENOVATE_INCLUDE_PATHS" \
    -e RENOVATE_BOT="$RENOVATE_BOT" \
    -v "$GIT_REPO:/tmp/local-git-repo" \
    --workdir /tmp/local-git-repo \
    ghcr.io/renovatebot/renovate \
    --platform=local \
    --semantic-commits=disabled \
| tee renovate.log

#    --dry-run="true" \
