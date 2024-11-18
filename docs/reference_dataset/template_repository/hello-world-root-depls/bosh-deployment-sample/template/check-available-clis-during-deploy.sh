#!/bin/sh

set -e

echo "==== List CLIs ===="
echo "Bosh cli is available"
bosh --version
echo "---"
echo "cf is available"
cf --version
echo "---"
echo "credhub is available"
credhub --version
echo "---"
echo "spruce is available"
spruce --version
echo "---"
echo "bash is available"
bash --version
echo "---"
echo "envsubst is available"
envsubst --version
echo "---"
echo "jq is available"
jq --version
echo "---"
echo "==== End List CLIs ===="


