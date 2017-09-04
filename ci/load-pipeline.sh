#!/bin/sh

fly -t cf-ops-automation set-pipeline -p cf-ops-automation -c pipeline.yml -l private.yml