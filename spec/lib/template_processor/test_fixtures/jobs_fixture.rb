module Coa
  module TestFixtures
    require 'yaml'

    JOB_CONFIG = YAML.safe_load <<~YAML
      on_failure:
        put: failure-alert
        params:
          channel: ((slack-channel))
          icon_url: https://pbs.twimg.com/profile_images/714899641628753920/3C8UrVPf.jpg
          text: |
            ![failed](https://rawgit.com/orange-cloudfoundry/travis-resource/master/ci/images/concourse-red.png) Failed to deploy [[$BUILD_PIPELINE_NAME/$BUILD_JOB_NAME]($ATC_EXTERNAL_URL/teams/$BUILD_TEAM_NAME/pipelines/$BUILD_PIPELINE_NAME/jobs/$BUILD_JOB_NAME/builds/$BUILD_NAME)].
          username: Concourse
    YAML
  end
end
