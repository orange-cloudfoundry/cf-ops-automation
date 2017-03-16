#!/bin/sh
set -eu

bosh_host=$1
bosh_username=$2

bosh_password=$3

bosh -t "${bosh_host}" login ${bosh_username} -- "${bosh_password}"
bosh target "${bosh_host}"
