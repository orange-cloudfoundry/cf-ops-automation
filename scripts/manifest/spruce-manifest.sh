#!/bin/sh

set -eu

spruce merge \
  --prune secrets \
  --prune terraform_outputs \
  "$@"
