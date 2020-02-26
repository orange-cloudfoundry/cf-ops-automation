# require 'spec_helper.rb'
require 'yaml'
require 'tmpdir'

describe 'post_deploy task' do
  context 'Pre-requisite' do
    let(:task) { YAML.load_file 'concourse/tasks/post_bosh_deploy.yml' }

    it 'uses alphagov cf-cli image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match('governmentpaas/cf-cli')
    end
  end

  context 'when no script is detected' do
    generated_files = nil
    before(:context) do
      generated_files = Dir.mktmpdir

      @output = execute('-c concourse/tasks/post_bosh_deploy.yml ' \
        '-i scripts-resource=. ' \
        '-i template-resource=spec/tasks/post_deploy/a-template-resource ' \
        '-i credentials-resource=spec/tasks/post_deploy/credentials-resource ' \
        '-i additional-resource=spec/tasks/post_deploy/additional-resource ' \
        "-o generated-files=#{generated_files} ",
                        'CUSTOM_SCRIPT_DIR' => 'my-custom-script-dir',
                        'SECRETS_DIR' => '')
    end

    after(:context) do
      FileUtils.rm_rf generated_files
    end

    it 'displays an ignore message' do
      expect(@output).to include('ignoring post-deploy. No my-custom-script-dir/post-deploy.sh or post-bosh-deploy.sh detected')
    end

    it 'adds additional resource to generated' do
      expect(File).to exist(File.join(generated_files, 'my_additional_file.yml'))
    end
  end

  context 'when a script is detected' do
    generated_files = nil

    before(:context) do
      generated_files = Dir.mktmpdir

      @output = execute('-c concourse/tasks/post_bosh_deploy.yml ' \
        '-i scripts-resource=. ' \
        '-i template-resource=spec/tasks/post_deploy/a-template-resource ' \
        '-i credentials-resource=spec/tasks/post_deploy/credentials-resource ' \
        '-i additional-resource=spec/tasks/post_deploy/additional-resource ' \
        "-o generated-files=#{generated_files} ",
                        'CUSTOM_SCRIPT_DIR' => 'template-resource/a-root-depls',
                        'SECRETS_DIR' => 'credentials-resource/a-root-depls')
    end

    after(:context) do
      FileUtils.rm_rf generated_files
    end

    it 'displays an execution message' do
      expect(@output).to include('post deploy script detected')
    end

    %w[GENERATE_DIR BASE_TEMPLATE_DIR SECRETS_DIR].each do |env_var|
      it "adds #{env_var} to available environment variables" do
        expect(@output).to include("variable #{env_var} is available")
      end
    end

    it 'adds additional resource to generated' do
      expect(File).to exist(File.join(generated_files, 'my_additional_file.yml'))
    end
  end

  context 'when a legacy script is detected' do
    generated_files = nil

    before(:context) do
      generated_files = Dir.mktmpdir

      @output = execute('-c concourse/tasks/post_bosh_deploy.yml ' \
        '-i scripts-resource=. ' \
        '-i template-resource=spec/tasks/post_deploy/a-template-legacy-resource ' \
        '-i credentials-resource=spec/tasks/post_deploy/credentials-resource ' \
        '-i additional-resource=spec/tasks/post_deploy/additional-resource ' \
        "-o generated-files=#{generated_files} ",
                        'CUSTOM_SCRIPT_DIR' => 'template-resource/a-root-depls',
                        'SECRETS_DIR' => 'credentials-resource/a-root-depls')
    end

    after(:context) do
      FileUtils.rm_rf generated_files
    end

    it 'displays an execution message' do
      expect(@output).to include('**deprecated** LEGACY post bosh deploy script detected').and include('LEGACY POST-DEPLOY SCRIPT')
    end

    it 'adds additional resource to generated' do
      expect(File).to exist(File.join(generated_files, 'my_additional_file.yml'))
    end
  end
end
