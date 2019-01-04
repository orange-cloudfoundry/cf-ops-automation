#!/usr/bin/ruby

["bootstrap-all-init-pipelines",
 "control-plane",
 "hello-world-root-depls-generated",
 "hello-world-root-depls-update-generated",
 "hello-world-root-depls-bosh-generated",
 "hello-world-root-depls-concourse-generated",
 "hello-world-root-depls-init-generated",
 "hello-world-root-depls-pipeline-sample"].each do |pipeline|
  `fly -t bucc destroy-pipeline --pipeline #{pipeline} -n`
end
