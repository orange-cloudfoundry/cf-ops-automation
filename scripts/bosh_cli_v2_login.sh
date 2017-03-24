#!/bin/sh
set -e

BOSH_HOST=$1
BOSH_CLIENT=$2
BOSH_CLIENT_SECRET=$3
BOSH_CERT_FILE=$4


echo "targeting ${BOSH_HOST}"

DIRECTOR_IP_URL_WITHOUT_PORT=${BOSH_HOST%%:25555}
DIRECTOR_IP=$(nslookup ${DIRECTOR_IP_URL_WITHOUT_PORT##https://} 2>/dev/null|grep Address|cut -d':' -f2)

if [ -n "$BOSH_CERT_FILE" ]
then
  CA_CERT_FILE="--ca-cert=${BOSH_CERT_FILE}"
fi

bosh alias-env -e $DIRECTOR_IP $CA_CERT_FILE ${BOSH_HOST}
export BOSH_ENVIRONMENT=${BOSH_TARGET}
