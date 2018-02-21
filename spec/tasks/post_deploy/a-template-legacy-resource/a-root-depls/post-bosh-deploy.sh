#!/bin/sh -e

check_var(){
    name=$1
#    if [ -z "$(eval $(echo '$'${name}))" ]
    if [ -z "$(printenv ${name})" ]
    then
        echo "variable $name is missing"
        exit 1
    else
        echo "variable $name is available"
    fi
}

echo "LEGACY POST-DEPLOY SCRIPT"
echo "Available env"
echo "=================="
env
echo "=================="
check_var GENERATE_DIR
check_var BASE_TEMPLATE_DIR
check_var SECRETS_DIR



