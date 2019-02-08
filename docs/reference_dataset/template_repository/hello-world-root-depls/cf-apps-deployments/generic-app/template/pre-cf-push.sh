#!/bin/sh

echo 'Hello, World!'
echo 'Here you can execute shell commands before deploying'
cp "${BASE_TEMPLATE_DIR}"/static-app/* "${GENERATE_DIR}"