require 'spec_helper'
require 'coa_env_bootstrapper/base'
require 'coa_env_bootstrapper/concourse'

describe CoaEnvBootstrapper::Concourse do
  let(:config_dir) { new_tmpdir_path }
  let(:fly_login_cmd) do
    "fly login --target bucc \
--concourse-url http://example.com \
--username 'concourse_username' \
--password 'concourse_password' -k && \
fly --target bucc sync"
  end
  let(:concourse_creds_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'concourse_prereqs.yml') }
  let(:pipeline_creds_path) { File.join(fixtures_dir('lib'), 'coa_env_bootstrapper', 'pipeline_creds.yml') }
  let(:ceb) { CoaEnvBootstrapper::Base.new([concourse_creds_path]) }

  before { FileUtils.mkdir config_dir }

  after { FileUtils.rm_r config_dir }

  describe '.new'

  describe '#upload_pipelines' do
    let(:git_server_ip) { "5.6.7.8" }
    let(:ceb) { CoaEnvBootstrapper::Base.new([concourse_creds_path, pipeline_creds_path]) }
    let(:concourse) { described_class.new(ceb) }
    let(:generated_pipeline_creds_path) { File.join(config_dir, "pipeline_credentials.yml") }
    let(:generated_creds) { { "secret" => "secret" } }
    let(:set_pipeline_cmd) do
      "fly --target bucc set-pipeline --non-interactive \
--pipeline bootstrap-all-init-pipelines \
--config #{CoaEnvBootstrapper::PROJECT_ROOT_DIR}/concourse/pipelines/bootstrap-all-init-pipelines.yml \
--load-vars-from #{generated_pipeline_creds_path} \
--var paas-templates-uri='git://#{git_server_ip}/paas-templates' \
--var secrets-uri='git://#{git_server_ip}/secrets' \
--var concourse-micro-depls-target='http://example.com' \
--var concourse-micro-depls-username='concourse_username' \
--var concourse-micro-depls-password='concourse_password'"
    end
    let(:pipeline_creds_content) do
      YAML.dump(YAML.load_file(pipeline_creds_path)["pipeline_credentials"].merge(generated_creds))
    end

    it "write down the concourse credentials and run the 'set-pipeline' command" do
      allow(concourse).to receive(:run_cmd).and_return(:success)
      allow(ceb.git).to receive(:server_ip).and_return(git_server_ip)

      concourse.upload_pipelines(config_dir, generated_creds)

      pipeline_creds = File.read(generated_pipeline_creds_path)
      expect(pipeline_creds).to eq(pipeline_creds_content)
      expect(concourse).to have_received(:run_cmd).with(fly_login_cmd)
      expect(concourse).to have_received(:run_cmd).with(set_pipeline_cmd)
    end
  end

  describe '#unpause_pipelines' do
    let(:concourse) { described_class.new(ceb) }
    let(:fly_unpause_pipeline_cmd) do
      "fly --target bucc unpause-pipeline --pipeline bootstrap-all-init-pipelines"
    end

    it "runs the `fly unpause-pipelines` command" do
      allow(concourse).to receive(:run_cmd)

      concourse.unpause_pipelines

      expect(concourse).to have_received(:run_cmd).with(fly_login_cmd)
      expect(concourse).to have_received(:run_cmd).with(fly_unpause_pipeline_cmd)
    end
  end

  describe '#trigger_jobs' do
    let(:concourse) { described_class.new(ceb) }
    let(:fly_trigger_job_cmd) do
      "fly --target bucc trigger-job --job bootstrap-all-init-pipelines/bootstrap-init-pipelines"
    end

    it "runs the `fly trigger-jobs` command" do
      allow(concourse).to receive(:run_cmd)

      concourse.trigger_jobs

      expect(concourse).to have_received(:run_cmd).with(fly_login_cmd)
      expect(concourse).to have_received(:run_cmd).with(fly_trigger_job_cmd)
    end
  end
end
