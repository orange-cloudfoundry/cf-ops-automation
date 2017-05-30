#!/usr/bin/env bash
usage() { echo "Usage: $0 -a <app_name> -s <path_to_secrets> [-d <depls_name>]" 1>&2; exit 1; }

DEPLS=ops-depls
while getopts ":s:d:a:" o; do
    case "${o}" in
        a)
            APP_NAME=$OPTARG
            ;;
        s)
            SECRETS=$(readlink -e $OPTARG)
            ;;
        d)
            DEPLS=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "L'option $OPTARG requiert un argument"
            exit 1
            ;;
        *)
            usage
            ;;
    esac
done
if [ -z "$APP_NAME" ] || [ -z "$SECRETS" ] || [ -z "$DEPLS" ]; then
    usage
fi

BASEDIR=$(readlink -e $(dirname $0))
COMMON_PATH=${DEPLS}/cf-apps-deployments


export OUTPUT_DIR=${OUTPUT_DIR:-/tmp}
export COMMON_SCRIPT_DIR=${COMMON_SCRIPT_DIR:-$BASEDIR/manifest}
export SPRUCE_SCRIPT_DIR=${SPRUCE_SCRIPT_DIR:-$BASEDIR/manifest}
export YML_TEMPLATE_DIR=${BASEDIR}/../${COMMON_PATH}/${APP_NAME}/template
export SPRUCE_FILE_BASE_PATH=${SECRETS}/${COMMON_PATH}
export YML_FILES="${SECRETS}/${COMMON_PATH}/${APP_NAME}/secrets/meta.yml \
    ${SECRETS}/${COMMON_PATH}/${APP_NAME}/secrets/secrets.yml \
    ${SECRETS}/shared/secrets.yml"


${BASEDIR}/manifest/manifest-lifecycle-generation.sh