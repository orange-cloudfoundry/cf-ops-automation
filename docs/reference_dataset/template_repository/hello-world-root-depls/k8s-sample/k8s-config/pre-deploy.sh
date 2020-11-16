#!/bin/sh
set -e #exit en error

echo 'Hello, World!'
echo "I'm '$BASE_TEMPLATE_DIR/pre-deploy.sh' script"
echo "I execute scripts in '$BASE_TEMPLATE_DIR/', matching ${FILE_EXECUTION_FILTER}"
echo 'Here you can execute shell commands before deploying'
