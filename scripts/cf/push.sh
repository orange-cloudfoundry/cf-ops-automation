#!/bin/sh

set -e
set -o pipefail

validate() {
  FAILURE=0
  if   [ -z "$CF_API_URL" ]; then
    echo     "missing CF_API_URL"
    FAILURE=$((1 + $FAILURE))
  fi

  if   [ -z "$CF_USERNAME" ]; then
    echo     "missing CF_USERNAME"
    FAILURE=$((2 + $FAILURE))
  fi

  if   [ -z "$CF_PASSWORD" ]; then
    echo     "missing CF_PASSWORD"
    FAILURE=$((4 + $FAILURE))
  fi

  if   [ $FAILURE -ne 0 ]; then
    exit     $FAILURE
  fi
}

validate

CURRENT_DIR=$(pwd)
OUTPUT_DIR=${OUTPUT_DIR:-${CURRENT_DIR}/generated-files}
COMMON_SCRIPT_DIR=${COMMON_SCRIPT_DIR:-scripts-resource/scripts/cf}
ADDITIONAL_RESOURCE=${ADDITIONAL_RESOURCE:-additional-resource}

CF_MANIFEST=${CF_MANIFEST:-manifest.yml}
CF_ENV_FILE="${CUSTOM_SCRIPT_DIR}"/cf-env.sh

cf --version

API_OPTIONS="--skip-ssl-validation"

#TODO add an option to manage ssl validation
cf api "$CF_API_URL" $API_OPTIONS
cf auth "$CF_USERNAME" "$CF_PASSWORD"

echo "copying file from $ADDITIONAL_RESOURCE to $OUTPUT_DIR"
cp -r $ADDITIONAL_RESOURCE/. $OUTPUT_DIR/

if [ -n "$CUSTOM_SCRIPT_DIR" ] && [ -f "$CUSTOM_SCRIPT_DIR/pre-cf-push.sh" ]; then
  echo   "pre CF push script detected - Available Environment variables: GENERATE_DIR: <$OUTPUT_DIR> | BASE_TEMPLATE_DIR: <$CUSTOM_SCRIPT_DIR>"
  chmod   +x "${CUSTOM_SCRIPT_DIR}"/pre-cf-push.sh
  GENERATE_DIR=$OUTPUT_DIR   BASE_TEMPLATE_DIR=$CUSTOM_SCRIPT_DIR "$CUSTOM_SCRIPT_DIR"/pre-cf-push.sh
else
  echo   "ignoring pre CF push. No $CUSTOM_SCRIPT_DIR/pre-cf-push.sh detected"
fi

cf target -o "$CF_ORG" -s "$CF_SPACE"

CF_PUSH_OPTIONS="--strategy rolling"
echo "To override default option, create 'cf-env' file alongside 'pre-cf-push.sh'. And set a shell variable, named 'CF_PUSH_OPTIONS', to expected value - Default: $CF_PUSH_OPTIONS"

if [ -f "$CF_ENV_FILE" ];then
  echo "Overriding CF push options"
  source $CF_ENV_FILE
fi

echo "CF push options: $CF_PUSH_OPTIONS"

set +e
cf push -f ${CF_MANIFEST} ${CF_PUSH_OPTIONS} 2>&1 | tee /tmp/cf-push.log
ret_code=$?
if [ $ret_code -ne 0 ]; then
  DISPLAY_LOG_CMD=$(  grep "TIP: use 'cf logs" /tmp/cf-push.log | cut -d\' -f2)
  eval   $DISPLAY_LOG_CMD
  exit   $ret_code
fi
