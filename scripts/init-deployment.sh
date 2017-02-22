#!/usr/bin/env bash

usage(){
    echo "$0 -t <micro-depls|master-depls|ops-depls|inception> -n <name>" 1>&2
    echo -e "\t -d deployment type (micro-depls|master-depls|ops-depls|inception) " 1>&2
    echo -e "\t -n deployment name" 1>&2
    exit 1
}
set -x

while getopts "t:n:" option; do
    case "${option}" in
        n)
            DEPLOYMENT_NAME=$OPTARG
            ;;
        t)
            if [ $OPTARG == "micro-depls" -o $OPTARG == "master-depls" -o $OPTARG == "ops-depls" -o $OPTARG == "inception" ]
            then
                DEPLOYMENT_TYPE=$OPTARG
            else
                usage
            fi
            ;;
        \?)
          echo "Invalid option: $OPTARG" >&2
          ;;
        *)
            usage
            ;;
    esac
done

if [ -z "${DEPLOYMENT_NAME}" ]
then
    echo "Missing deployment name" 1>&2
    usage
fi

if [ -z "${DEPLOYMENT_TYPE}" ]
then
    echo "Missing deployment type" 1>&2
    usage
fi

echo "Initializing deployment : ${DEPLOYMENT_TYPE}/${DEPLOYMENT_NAME}"
mkdir -p ${DEPLOYMENT_TYPE}/${DEPLOYMENT_NAME}

pushd ${DEPLOYMENT_TYPE}/${DEPLOYMENT_NAME}
echo "Creating template link: ${DEPLOYMENT_TYPE}/${DEPLOYMENT_NAME}/template"
ln -sf ../../paas-templates/${DEPLOYMENT_TYPE}/${DEPLOYMENT_NAME}/template template

echo "Creating secrets link: ${DEPLOYMENT_TYPE}/${DEPLOYMENT_NAME}/secrets"
ln -sf ../../secrets/${DEPLOYMENT_TYPE}/${DEPLOYMENT_NAME}/secrets secrets
popd


