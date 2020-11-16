#!/bin/sh
set -e #exit en error

echo "This is an hook to run scripts at root-deployment level"
echo "I'm '$BASE_TEMPLATE_DIR/deploy.sh' script"
echo "I execute scripts in '$BASE_TEMPLATE_DIR/', matching ${FILE_EXECUTION_FILTER}"
