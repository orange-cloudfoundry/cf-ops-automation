#!/bin/sh
#--- Colors and styles
export RED='\033[1;31m'
export YELLOW='\033[1;33m'
export STD='\033[0m'

echo 'Bye bye, World!'
echo 'Here you can execute shell commands after deploying'

APP_NAME="generic-app"

# Login to Cloud Foundry, all CF_* variables are injected by COA
cf login --skip-ssl-validation -a "${CF_API_URL}" -u "${CF_USERNAME}" -p "${CF_PASSWORD}" -o "${CF_ORG}" -s "${CF_SPACE}"
result=$?

if [ "${result}" != "0" ] ; then
	printf "\n%bERROR: Cannot log into CF%b\n\n" "${RED}" "${STD}"
	exit 1
fi

cf env "${APP_NAME}"
cf apps
cf delete -r -f "${APP_NAME}"
