#!/bin/sh

echo 'Hello, World from "pre-cf-push.sh" !'
echo 'Here you can execute shell commands before deploying'
cp "${BASE_TEMPLATE_DIR}"/static-app/* "${GENERATE_DIR}"

echo "Allow current user to push apps (this is required only once:) )"
cf set-space-role $CF_USERNAME $CF_ORG $CF_SPACE SpaceDeveloper