#!/bin/sh
set -e #exit en error

echo 'Bye bye, World!'
echo "I'm '$BASE_TEMPLATE_DIR/post-deploy.sh' script"
echo "I execute scripts in '$BASE_TEMPLATE_DIR/', matching ${FILE_EXECUTION_FILTER}"
echo 'Here you can execute shell commands after deploying'
