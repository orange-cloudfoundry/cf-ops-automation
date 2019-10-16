#!/bin/sh
set -e
PATH_PREFIX=${PATH_PREFIX:-templates-resource}
OUTPUT_PATH=${OUTPUT_PATH:-check-configuration-result}

DEPLOYMENT_PATH=${PATH_PREFIX}/${ROOT_DEPLOYMENT}/${DEPLOYMENT}
LOG_FILE="$OUTPUT_PATH/errors.log"
printf "" > ${LOG_FILE}

echo "checking deployment-dependencies.yml @ $DEPLOYMENT_PATH"
DEPLOYMENT_DEPENDENCIES_PATH=$(realpath "$DEPLOYMENT_PATH/deployment-dependencies.yml"|grep ${ROOT_DEPLOYMENT})
if [[ -z "$DEPLOYMENT_DEPENDENCIES_PATH" ]];then
  echo "ERROR: deployment-dependencies.yml for $DEPLOYMENT cannot be a symlink outside $ROOT_DEPLOYMENT" >> ${LOG_FILE}
fi

echo "Paths to check: ${SCAN_PATHS}"
for scan_path in ${SCAN_PATHS};do
    echo "Checking $scan_path - $PATH_PREFIX/$scan_path"
    if [[ ! -e "$PATH_PREFIX/$scan_path" ]]; then
      echo "ERROR: inconsistency detected in ${DEPLOYMENT}"
      echo "ERROR: $scan_path does not exist ($DEPLOYMENT_PATH), please check related deployment-dependencies.yml" >> ${LOG_FILE}
    fi
done

CONFIG_PREFIX=${CONFIG_PREFIX:-config-resource}
CONFIG_DEPLOYMENT_PATH=${CONFIG_PREFIX}/${ROOT_DEPLOYMENT}/${DEPLOYMENT}/secrets
echo "Checking local scan consistency"
if [[ "$LOCAL_SECRETS_SCAN" = "true" ]];then
  echo "Local secrets scan enabled for ${DEPLOYMENT}"
  if [[ ! -e "$CONFIG_DEPLOYMENT_PATH/secrets.yml" && ! -e "$CONFIG_DEPLOYMENT_PATH/meta.yml" ]];then
    echo "ERROR: inconsistency detected in ${DEPLOYMENT}"
    echo "ERROR: local_deployment_scan enabled in deployment-dependencies.yml for ${DEPLOYMENT}, but no config files (meta.yml, secrets.yml) detected at $CONFIG_DEPLOYMENT_PATH" >> ${LOG_FILE}
  fi
else
  echo "Local secrets scan disabled for ${DEPLOYMENT}"
  if [[ -e "$CONFIG_DEPLOYMENT_PATH/secrets.yml" || -e "$CONFIG_DEPLOYMENT_PATH/meta.yml" ]];then
    echo "ERROR: inconsistency detected in ${DEPLOYMENT}"
    echo "ERROR: local_deployment_scan disabled  in deployment-dependencies.yml for ${DEPLOYMENT}, but config files (meta.yml, secrets.yml) detected at $CONFIG_DEPLOYMENT_PATH" >> ${LOG_FILE}
  fi
fi

if [[ -s ${LOG_FILE}  ]];then
    echo "Error(s):"
    cat ${LOG_FILE}
    exit 1
fi
