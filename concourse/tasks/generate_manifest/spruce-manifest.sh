#!/bin/sh

set -eu

spruce merge \
  --prune secrets \
  --prune meta-inf \
  --prune terraform_outputs \
  "$@"
