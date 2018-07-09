#!/usr/bin/env bash

usage(){
    echo "$0 -t <micro-depls|master-depls|ops-depls|expe-depls|inception> -n <name>" 1>&2
    echo -e "\t -d deployment type (micro-depls|master-depls|ops-depls|expe-depls|inception) " 1>&2
    echo -e "\t -n deployment name" 1>&2
    exit 1
}

while getopts "t:n:" option; do
    case "${option}" in
        n)
            DEPLOYMENT_NAME=$OPTARG
            ;;
        t)
            if [ $OPTARG == "micro-depls" -o $OPTARG == "master-depls" -o $OPTARG == "ops-depls" -o $OPTARG == "expe-depls" -o $OPTARG == "inception" ]
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

echo "Creating template dir: ${DEPLOYMENT_TYPE}/${DEPLOYMENT_NAME}/template"
mkdir -p ${DEPLOYMENT_TYPE}/${DEPLOYMENT_NAME}/template

echo "Creating template file: ${DEPLOYMENT_TYPE}/${DEPLOYMENT_NAME}/template/${DEPLOYMENT_NAME}-tpl.yml"
touch ${DEPLOYMENT_TYPE}/${DEPLOYMENT_NAME}/template/${DEPLOYMENT_NAME}-tpl.yml

echo "Creating dummy deployment-dependencies-sample.yml"
target=${DEPLOYMENT_TYPE}/${DEPLOYMENT_NAME}/deployment-dependencies-sample.yml
echo "---" >"${target}"
{
    echo "deployment:"
    echo "  bosh-deployment:"
    echo "    releases:"
    echo "      xxx_boshrelease:"
    echo "        base_location: https://bosh.io/d/github.com/"
    echo "        repository:"
    echo ""
} >>"${target}"

echo "####### WARNING #########"
echo "Don't forget to  rename ${DEPLOYMENT_TYPE}/${DEPLOYMENT_TYPE}/deployment-dependencies-sample.yml to ${DEPLOYMENT_TYPE}/${DEPLOYMENT_TYPE}/deployment-dependencies.yml when you're done !"
