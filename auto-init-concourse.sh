#!/usr/bin/env bash

echo "Deploy on Concourse-MICRO"

echo "Load micro-bosh-init-pipeline"
fly -t cw-pp-micro set-pipeline -p micro-bosh-init-pipeline -c concourse/pipelines/micro-bosh-init-pipeline.yml  -l micro-depls/concourse-micro/pipelines/credentials-micro-bosh-init-pipeline.yml -l micro-depls/micro-depls-versions.yml

echo "Load micro-depls-pipeline"
fly -t cw-pp-micro set-pipeline -p micro-depls-pipeline -c concourse/pipelines/micro-depls-pipeline.yml  -l micro-depls/concourse-micro/pipelines/credentials-micro-depls-pipeline.yml -l micro-depls/micro-depls-versions.yml

echo "Load master-depls-pipeline"
fly -t cw-pp-micro set-pipeline -p master-depls-pipeline -c concourse/pipelines/master-depls-pipeline.yml  -l micro-depls/concourse-master/pipelines/credentials-master-depls-pipeline.yml -l master-depls/master-depls-versions.yml

echo "Load ops-depls-pipeline"
fly -t cw-pp-micro set-pipeline -p ops-depls-pipeline -c concourse/pipelines/ops-depls-pipeline.yml  -l master-depls/concourse-ops/pipelines/credentials-ops-depls-pipeline.yml -l ops-depls/ops-depls-versions.yml


echo "Load master-depls-pipeline-GENERATED"
fly -t cw-pp-micro set-pipeline -p master-depls-pipeline-generated -c concourse/pipelines/master-depls-generated.yml  -l micro-depls/concourse-master/pipelines/credentials-master-depls-pipeline.yml -l master-depls/master-depls-versions.yml
