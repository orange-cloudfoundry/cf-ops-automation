#!/usr/bin/env bash

# tune shell check rules: SC2164 https://github.com/koalaman/shellcheck/wiki/SC2164
# shellcheck disable=SC2038
# Warning:(12, 5) Shellcheck find: Use -print0/-0 or -exec + to allow for non-alphanumeric filenames. [SC2038]


#set -o xtrace # debug mode
set -o errexit # exit on errors

function usage() {
    echo "Usage: $0 -c <CONFIG_REPOSITORY_PATH> [-a <CF_OPS_AUTOMATION_PATH>] [-t <PAAS_TEMPLATES_PATH>]"
    exit 1
}

function need_upgrade() {
    echo "checking whether upgrade is needed"
    find "${CONFIG_REPO}" -name "ci-deployment-overview.yml" | xargs grep -n mattermost
    return $?
}

while getopts ":c:t:a:" o; do
    case "${o}" in
        a)
            CF_OPS_AUTOMATION=$OPTARG
            ;;
        c)
            CONFIG_REPO=$OPTARG
            ;;
        t)
            PAAS_TEMPLATES=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Argument required by $OPTARG"
            exit 1
            ;;
        *)
            usage
            ;;
    esac
done

if [ -z "${CONFIG_REPO}" ]; then
    usage
fi


echo "Migrating config repo clone at ${CONFIG_REPO}"

if ! need_upgrade ; then
    echo "No need to apply upgrade."
    exit 0
fi

echo "removing deprecated mattermost certs from ci-deployment overview:"
find "${CONFIG_REPO}" -name "ci-deployment-overview.yml" | xargs -n 1 sed -i -e '/^.*credentials-mattermost-certs.yml/d'

echo "expecting no more mattermost in following list:"
set +o errexit # don't exit on grep finding no file
find "${CONFIG_REPO}" -name "ci-deployment-overview.yml" | xargs grep -n mattermost

echo "please review the changes applied and commit/push"
