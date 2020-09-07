require 'spec_helper'
require 'tmpdir'
require_relative 'test_helper'

describe 'generate-depls for bosh pipeline' do
  ci_path = Dir.pwd
  test_path = File.join(ci_path, '/spec/scripts/generate-depls')
  fixture_path = File.join(test_path, '/fixtures')

  let(:output_path) { Dir.mktmpdir }
  let(:templates_path) { "#{fixture_path}/templates" }
  let(:secrets_path) { "#{fixture_path}/secrets" }
  let(:depls_name) { 'simple-depls' }
  let(:iaas_type) { 'my-custom-iaas' }
  let(:profiles) { %w[ntp-profile] }
  let(:options) { "-d #{depls_name} -o #{output_path} -t #{templates_path} -p #{secrets_path} --iaas #{iaas_type} --no-dump -i bosh --profiles #{profiles.join(',')}" }
  let(:pipeline) { TestHelper.load_generated_pipeline(output_path, "#{depls_name}-bosh-generated.yml") }
  let(:cleanup) { FileUtils.rm_rf(output_path) unless output_path.nil? }

  context 'when a simple deployment is used' do
    after do
      cleanup
    end

    context 'when generate-depls is executed' do
      let(:pipeline) { TestHelper.load_generated_pipeline(output_path, 'simple-depls-bosh-generated.yml') }

      before do
        TestHelper.generate_deployment_bosh_ca_cert(secrets_path)
        @stdout_str, @stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
      end

      it 'does not display an error message' do
        expect(@stderr_str).to eq('')
      end

      it 'processes only bosh-pipeline template' do
        expect(@stdout_str).to include('processing ./concourse/pipelines/template/bosh-pipeline.yml.erb').and \
          include('1 concourse pipeline templates were processed')
      end

      it 'generates deployment using bosh cli v2, by default' do
        expect(pipeline['resources'].select { |resource| resource['name'] == 'ntp-with-scan-deployment' }.first).to include({ 'type' => 'bosh-deployment-v2' })
      end

      it 'generates on-failure on each job' do
        expect(pipeline['jobs'].reject { |jobs| jobs['on_failure'] }).to be_empty
      end

      context 'when a generated reference depls pipeline file is used' do
        it_behaves_like 'pipeline checker', 'simple-depls-bosh-generated.yml', 'simple-depls-bosh-ref.yml'
      end
    end

    context 'when scripting lifecycle feature is valid' do
      # if template directory contains scripts with specific name, then these scripts are executed, using the following order :
      #  1: post-generate.sh: can execute shell operation or spruce task.
      #         **Restrictions**: as the post-generation script is executed in the same docker image running spruce, no spiff is available.
      #  2: pre-bosh-deploy.sh: can execute shell operation (bosh, credhub, cf and spruce).
      #  3: post-bosh-deploy.sh: can execute shell operation (including curl).

      let(:deploy_ntp) { pipeline['jobs'].select { |job| job['name'] == 'deploy-ntp-with-scan' }.first }
      let(:deployment_plan) { deploy_ntp.select { |item| item['plan'] }['plan'] }
      let(:lifecycle_order) do
        lifecycle = {}
        deployment_plan&.select { |item| item['task'] }
          .each_with_index do |task, index|
            case task['task']
            when 'generate-ntp-with-scan-manifest'
              lifecycle['post-generate'] = index
            when 'execute-ntp-with-scan-pre-bosh-deploy'
              lifecycle['pre-bosh-deploy'] = index
            when 'execute-ntp-with-scan-post-bosh-deploy'
              lifecycle['post-bosh-deploy'] = index
              # do not add an else as other task may exist
            end
          end
        lifecycle
      end

      before do
        TestHelper.generate_deployment_bosh_ca_cert(secrets_path)
        @stdout_str, @stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
      end

      it 'generates a post-generate task' do
        manifest_generation_task = deployment_plan.select { |task| task['task'] == 'generate-ntp-with-scan-manifest' }.first
        expect(manifest_generation_task).to include('file' => 'cf-ops-automation/concourse/tasks/generate_manifest/task.yml')
      end

      it 'generates a pre-bosh-deploy task' do
        pre_bosh_deploy_task = deployment_plan.select { |task| task['task'] == 'execute-ntp-with-scan-pre-bosh-deploy' }.first
        expect(pre_bosh_deploy_task).to include('file' => 'cf-ops-automation/concourse/tasks/pre_bosh_deploy.yml')
      end

      it 'generates a post-bosh task' do
        post_bosh_deploy_task = deployment_plan.select { |task| task['task'] == 'execute-ntp-with-scan-post-bosh-deploy' }.first
        expect(post_bosh_deploy_task).to include('file' => 'cf-ops-automation/concourse/tasks/post_bosh_deploy.yml')
      end

      it 'executes post-generate task first' do
        expect(lifecycle_order['post-generate']).to be < lifecycle_order['pre-bosh-deploy']
      end

      it 'executes post-generate task second ' do
        expect(lifecycle_order['pre-bosh-deploy']).to be < lifecycle_order['post-bosh-deploy']
      end

      it 'executes post-generate task third ' do
        expect(lifecycle_order['post-bosh-deploy']).to be > lifecycle_order['pre-bosh-deploy']
      end
    end
  end

  context 'when deployment deletion is detected' do
    let(:depls_name) { 'delete-depls' }

    before do
      TestHelper.generate_deployment_bosh_ca_cert(secrets_path)
      @stdout_str, @stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
    end

    it 'no error message are displayed' do
      expect(@stderr_str).to eq('')
    end

    context 'when a minimal delete depls pipeline is generated' do
      it_behaves_like 'pipeline checker', 'delete-depls-bosh-generated.yml', 'delete-depls-bosh-ref.yml'
    end

    it 'generates on-failure on each job' do
      expect(pipeline['jobs'].reject { |jobs| jobs['on_failure'] }).to be_empty
    end

    it 'generates delete-deployments-review job with valid task' do
      current_job = pipeline['jobs'].select { |job| job['name'] == 'delete-deployments-review' }&.first
      current_task = current_job.select { |item| item['plan'] }['plan'].select { |item| item['task'] == 'prepare-deployment-to-be-deleted' }&.first
      expect(current_task).to include('file' => 'cf-ops-automation/concourse/tasks/bosh_delete_plan/task.yml').and \
        include('params' => { 'ROOT_DEPLOYMENT_NAME' => depls_name, "BOSH_TARGET" => "((bosh-target))", "BOSH_CLIENT" => "((bosh-username))", "BOSH_CLIENT_SECRET" => "((bosh-password))", "BOSH_CA_CERT" => "config-resource/shared/certs/internal_paas-ca/server-ca.crt" })
    end

    it 'generates approve-and-delete-disabled-deployments job with valid task' do
      current_job = pipeline['jobs'].select { |job| job['name'] == 'approve-and-delete-disabled-deployments' }&.first
      current_task = current_job.select { |item| item['plan'] }['plan'].select { |item| item['task'] == 'delete-deployments' }&.first
      expect(current_task).to include('file' => 'cf-ops-automation/concourse/tasks/bosh_delete_apply/task.yml').and \
        include('params' => { 'ROOT_DEPLOYMENT_NAME' => depls_name, "BOSH_TARGET" => "((bosh-target))", "BOSH_CLIENT" => "((bosh-username))", "BOSH_CLIENT_SECRET" => "((bosh-password))", "BOSH_CA_CERT" => "config-resource/shared/certs/internal_paas-ca/server-ca.crt", "COMMIT_MESSAGE" => "${ROOT_DEPLOYMENT_NAME}: Automated Bosh and Secrets Cleanup" }).and \
          include('ensure' => { 'get_params' => { 'submodules' => 'none', 'depth' => 0 }, 'params' => { 'rebase' => true, 'repository' => 'updated-config-resource' }, 'put' => 'secrets-full-writer' })
    end
  end

  context 'when a deployment without explicit dependency is used' do
    let(:depls_name) { 'no-dependency-depls' }

    before do
      TestHelper.generate_deployment_bosh_ca_cert(secrets_path)
      @stdout_str, @stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
    end

    it 'no error message are displayed' do
      expect(@stderr_str).to eq('')
    end

    it 'generates on-failure on each job' do
      expect(pipeline['jobs'].reject { |jobs| jobs['on_failure'] }).to be_empty
    end

    it 'does not generate bosh release resource' do
      current_resources = pipeline['resources'].select { |resource| resource['type'] == 'type: bosh-io-release' || resource['type'] == 'type: github-release' }&.first

      expect(current_resources).to match(nil)
    end
  end

  describe 'depls-pipeline template pre-requisite' do
    context 'when template is processed'
  end

  describe 'dual deployment mode' do
    it 'handle bosh deployment using bosh cli v1'
    it 'handle bosh deployment using bosh cli v2'
  end

  describe 'file generation from template feature'
  describe 'git extented_scan_path feature'
  describe 'tfvars support feature'
  describe 'errand support feature'
end
