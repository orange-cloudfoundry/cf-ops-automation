# require 'spec_helper.rb'
require 'yaml'
require 'tmpdir'

describe 'cf push task' do
  context 'Pre-requisite: a valid Cloudfoundry instance with existing user with password, org' do
    it 'is not possible yet (credentials leak)'
  end

  context 'when no custom pre-push script is detected' do
    generated_files = nil
    before(:context) do
      generated_files = Dir.mktmpdir

      # @output = execute('-c concourse/tasks/cf_push.yml ' \
      #   '-i scripts-resource=. ' \
      #   '-i templates-resource=spec/tasks/cf_push/template-resource ' \
      #   '-i credentials-resource=spec/tasks/cf_push/credentials-resource ' \
      #   '-i additional-resource=spec/tasks/cf_push/additional-resource ' \
      #   "-o generated-files=#{generated_files} ",
      #   'CUSTOM_SCRIPT_DIR' =>'',
      #   'SECRETS_DIR' => '' )
    end

    after(:context) do
      FileUtils.rm_rf generated_files
    end

    it 'displays an ignore message'
    # expect(@output).to include('ignoring pre CF push. No /pre-cf-push.sh detected')
  end

  context 'when a custom pre-push script script is detected' do
    generated_files = nil
    before(:context) do
      generated_files = Dir.mktmpdir

      # @output = execute('-c concourse/tasks/cf_push.yml ' \
      #   '-i scripts-resource=. ' \
      #   '-i templates-resource=spec/tasks/cf_push/template-resource ' \
      #   '-i credentials-resource=spec/tasks/cf_push/credentials-resource ' \
      #   '-i additional-resource=spec/tasks/cf_push/additional-resource ' \
      #   "-o generated-files=#{generated_files} ",
      #                   'CUSTOM_SCRIPT_DIR' => 'template-resource/a-root-depls',
      #                   'SECRETS_DIR' => 'credentials-resource/a-root-depls')
    end

    after(:context) do
      FileUtils.rm_rf generated_files
    end

    %w[GENERATE_DIR BASE_TEMPLATE_DIR SECRETS_DIR CF_API_URL CF_USERNAME CF_PASSWORD CF_ORG CF_SPACE CF_MANIFEST].each do |env_var|
      it "adds #{env_var} to available environment variables"
      # do
      #   expect(@output).to include("variable #{env_var} is available")
      # end
    end

    it 'displays an execution message'
    # do
    #    expect(@output).to include('pre CF push script detected')
    # end

    it 'executes the detected custom pre-push script before executing the cf push command'

    it 'adds additional resource to generated'
  end
end
