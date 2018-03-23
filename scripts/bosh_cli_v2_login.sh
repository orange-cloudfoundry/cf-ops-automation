#!/bin/sh
set -e

BOSH_HOST=$1
BOSH_CERT_FILE=$2

bosh --version
echo "checking nslookup is available"
which nslookup
echo "nslookup found"

my_realpath() { echo $(cd $(dirname $1); pwd)/$(basename $1); }

if [ -n "$BOSH_CERT_FILE" ]
then
    echo "Using ca cert file: ${BOSH_CERT_FILE}"
    CA_CERT_FILE="--ca-cert=${BOSH_CERT_FILE}"
fi

ERROR_COUNT=0
if [ -z "$BOSH_CLIENT" ]
then
    echo "ERROR: missing environment variable: BOSH_CLIENT"
    ERROR_COUNT=$(($ERROR_COUNT+1))
fi

if [ -z "$BOSH_CLIENT_SECRET" ]
then
    echo "ERROR: missing environment variable: BOSH_CLIENT_SECRET"
    ERROR_COUNT=$(($ERROR_COUNT+1))
fi

if [ -z "$BOSH_CA_CERT" -a -z "$BOSH_CERT_FILE" ]
then
    echo "ERROR: missing environment variable, requires at least one of them: BOSH_CA_CERT or BOSH_CERT_FILE"
    ERROR_COUNT=$(($ERROR_COUNT+1))
fi


if [ $ERROR_COUNT -ne 0 ]
then
    exit $ERROR_COUNT
fi

if [ -n "$BOSH_CA_CERT"  ]
then
    export BOSH_CA_CERT=$(my_realpath $BOSH_CA_CERT)
fi

echo "targeting ${BOSH_HOST}"

DIRECTOR_IP_URL_WITHOUT_PORT=${BOSH_HOST%%:25555}
DIRECTOR_IP=$(nslookup ${DIRECTOR_IP_URL_WITHOUT_PORT##https://} 2>/dev/null|grep Address|cut -d':' -f2)

DIRECTOR_IP_NO_SPACE=$(echo $DIRECTOR_IP |tr -d [:blank:])
export BOSH_ENVIRONMENT="https://${DIRECTOR_IP_NO_SPACE}:25555"

echo "Using BOSH_ENVIRONMENT=${BOSH_ENVIRONMENT}"
bosh log-in $CA_CERT_FILE
bosh env
