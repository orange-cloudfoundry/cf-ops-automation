#!/bin/sh

set -eu

../../inception/template/spruce merge \
  --prune meta \
  --prune secrets \
  --prune terraform_outputs \
  "$@"
