#!/bin/sh -e

check_var(){
    name=$1
    if [ -z "$(printenv ${name})" ]
    then
        echo "variable $name is missing"
        exit 1
    else
        echo "variable $name is available"
    fi
}

echo "Available env"
echo "=================="
env
echo "=================="
check_var GENERATE_DIR
check_var BASE_TEMPLATE_DIR
check_var SECRETS_DIR

echo "Cloud Foundry specific vars"
check_var CF_API_URL
check_var CF_USERNAME
check_var CF_PASSWORD
check_var CF_ORG
check_var CF_SPACE
check_var CF_MANIFEST
