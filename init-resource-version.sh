#!/usr/bin/env bash


fly -t cw-pp-micro check-resource -r master-depls-generated/bosh --from version:260.4
fly -t cw-pp-micro check-resource -r master-depls-generated/bosh-stemcell --from version:3312.15

fly -t cw-pp-micro check-resource -r master-depls-generated/logsearch --from 203.0.0
fly -t cw-pp-micro check-resource -r master-depls-generated/logsearch-for-cloudfoundry --from  201.0.0
fly -t cw-pp-micro check-resource -r master-depls-generated/logsearch-for-cloudfoundry-operators --from version 30.0.0

fly -t cw-pp-micro check-resource -r ops-depls-generated/bosh --from version:260.4
fly -t cw-pp-micro check-resource -r ops-depls-generated/bosh-stemcell --from version:3312.15
fly -t cw-pp-micro check-resource -r ops-depls-generated/cf-rabbitmq --from version:215.0.0
fly -t cw-pp-micro check-resource -r ops-depls-generated/cf-routing --from version:0.143.0
fly -t cw-pp-micro check-resource -r ops-depls-generated/memcache --from version:3


fly -t cw-pp-micro check-resource -r master-depls-generated/concourse --from version:2.6.0
fly -t cw-pp-micro check-resource -r master-depls-generated/garden-runc --from version:1.1.0

fly -t cw-pp-micro check-resource -r micro-depls-generated/concourse --from version:2.6.0
fly -t cw-pp-micro check-resource -r micro-depls-generated/garden-runc-release --from version:1.1.0