#!/bin/bash
readonly base_dir="$(realpath $0 | xargs dirname)"

GIT_REPO="$base_dir"
LOG_LEVEL="${LOG_LEVEL:-debug}"
RENOVATE_ENABLED_MANAGERS="${RENOVATE_ENABLED_MANAGERS:-""}"
RENOVATE_INCLUDE_PATHS="${RENOVATE_INCLUDE_PATHS:-""}"
RENOVATE_PLATFORM="${RENOVATE_PLATFORM:-local}"
# See https://docs.renovatebot.com/presets-default/#githubcomtokenarg0
if [ -z "$GITHUB_TOKEN" ]; then
	echo -e "ERROR: missing GitHub token to allow github release version detection. Please set it before running this script, using \n export GITHUB_TOKEN=\"xxx\""
	exit 1
fi

#RENOVATE_TOKEN, see https://docs.renovatebot.com/self-hosted-configuration/#token

echo "Set LOG_LEVEL to manage log level. Default 'debug'.Current Log level: <$LOG_LEVEL>"
echo "Set RENOVATE_ENABLED_MANAGERS to restrict active managers. Current RENOVATE_ENABLED_MANAGERS: <$RENOVATE_ENABLED_MANAGERS> #Empty means all managers are enabled"
echo "Set RENOVATE_INCLUDE_PATHS to restrict renovate scan. Current RENOVATE_INCLUDE_PATHS: <$RENOVATE_INCLUDE_PATHS> #Empty means scan all paths"
echo "Git repo volume path: $GIT_REPO"

# We need distinct cache whether running in local or github platform
# Otherwise local tries to git update from cache and fails.
CACHED_TMP_RENOVATE="${CACHED_TMP_RENOVATE:-/tmp/renovate/${RENOVATE_PLATFORM}}"
echo "Renovate cache is mounted from ${CACHED_TMP_RENOVATE}"
mkdir -p "${CACHED_TMP_RENOVATE}"
du -sh "${CACHED_TMP_RENOVATE}"

echo "RENOVATE_PLATFORM=${RENOVATE_PLATFORM}. Set to github to test pull requests."
# https://docs.renovatebot.com/modules/platform/local/
# > Limitations: Branch creation is not supported
# See related issue https://github.com/renovatebot/renovate/issues/3609 for further context
if [[ ${RENOVATE_PLATFORM} == "github" ]]; then
	RENOVATE_REPOSITORIES="orange-cloudfoundry/$GIT_REPO"
	# See https://docs.renovatebot.com/self-hosted-configuration/#dryrun
	RENOVATE_DRY_RUN="${RENOVATE_DRY_RUN:-true}"
	echo "RENOVATE_DRY_RUN=${RENOVATE_DRY_RUN}. Set to false to actually create PRs."
	#Note: breaks with local platform, so only defined for gihtub
	RENOVATE_DRY_RUN_OPTS="--dry-run=${RENOVATE_DRY_RUN}"
fi

#set -x
# Usage: renovate [options] [repositories...]
docker run \
	--rm \
	-u $(id -u):$(id -g) \
	-e LOG_LEVEL="$LOG_LEVEL" \
	-e RENOVATE_TOKEN="$GITHUB_TOKEN" \
	-e RENOVATE_GITHUB_COM_TOKEN="$GITHUB_TOKEN" \
	-e RENOVATE_ENABLED_MANAGERS="$RENOVATE_ENABLED_MANAGERS" \
	-e RENOVATE_INCLUDE_PATHS="$RENOVATE_INCLUDE_PATHS" \
	-e RENOVATE_BOT="$RENOVATE_BOT" \
	-v "$GIT_REPO:/tmp/local-git-repo" \
	--workdir /tmp/local-git-repo \
	ghcr.io/renovatebot/renovate \
	--platform=local \
	--semantic-commits=disabled \
	${RENOVATE_DRY_RUN_OPTS} \
	${RENOVATE_REPOSITORIES} |
	tee renovate.log
#    --dry-run="true" \

# hint that renovate.log is created by this script.
ls -al renovate.log
