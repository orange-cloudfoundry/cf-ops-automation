# encoding: utf-8

require 'digest'
require 'yaml'
require 'open3'
require 'rspec'
require_relative 'test_helper'

# require 'spec_helper.rb'

describe 'generate-depls for depls pipeline' do

  ci_path = Dir.pwd
  test_path = File.join(ci_path, '/spec/scripts/generate-depls')
  fixture_path = File.join(test_path, '/fixtures')

  let(:output_path) { Dir.mktmpdir }
  let(:templates_path) { "#{fixture_path}/templates" }
  let(:secrets_path) { "#{fixture_path}/secrets" }
  let(:depls_name) { 'simple-depls' }
  let(:options) { "-d #{depls_name} -o #{output_path} -t #{templates_path} -p #{secrets_path} --no-dump -i ./concourse/pipelines/template/depls-pipeline.yml.erb" }
  let(:pipeline) { TestHelper.load_generated_pipeline(output_path, "#{depls_name}-generated.yml") }


  let(:setup_certificates) { TestHelper.create_test_root_ca "#{secrets_path}/shared/certs/internal_paas-ca/server-ca.crt" unless File.exist?("#{secrets_path}/shared/certs/internal_paas-ca/server-ca.crt") }
  let(:cleanup) { FileUtils.rm_rf(output_path) unless output_path.nil? }

  context 'when a simple deployment is used' do
    after do
      cleanup
    end

    context 'when generate-depls is executed' do

      let(:pipeline) { TestHelper.load_generated_pipeline(output_path, 'simple-depls-generated.yml') }

      before do
        setup_certificates
        @stdout_str, @stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
      end

      it 'does not display an error message' do
        expect(@stderr_str).to eq('')
      end

      it 'processes only depls-pipeline template' do
        expect(@stdout_str).to include('processing ./concourse/pipelines/template/depls-pipeline.yml.erb').and \
          include('1 concourse pipeline templates were processed')
      end

      it 'generates deployment using bosh cli v2, by default' do
        expect(pipeline['resources'].select{|resource| resource['name'] == 'ntp-deployment'}.first).to include({'type'=>'bosh-deployment-v2'})
      end

      it 'generates on-failure on each job' do
        expect(pipeline['jobs'].select{|jobs| !jobs['on_failure']}).to be_empty
      end

      context 'when a generated reference depls pipeline file is used' do
        it_behaves_like 'pipeline checker', 'simple-depls-generated.yml', 'simple-depls-ref.yml'
      end

    end

    context 'when scripting lifecycle feature is valid' do
      # if template directory contains scripts with specific name, then these scripts are executed, using the following order :
      #   1: post-generate.sh: can execute shell operation or spruce task.
      #         **Restrictions**: as the post-generation script is executed in the same docker image running spruce, no spiff is available.
      #   2: pre-bosh-deploy.sh: can execute shell operation or spiff task.
      #   3: post-bosh-deploy.sh: can execute shell operation (including curl).

        let(:deploy_ntp) { pipeline['jobs'].select{ |job| job['name'] == 'deploy-ntp' }.first }
        let(:deployment_plan) { deploy_ntp.select{ |item| item['plan'] }['plan'] }
        let(:lifecycle_order) {lifecycle={}
          deployment_plan&.select{ |item| item['task'] }
            .each_with_index do|task, index |
            case task['task']
              when 'generate-ntp-manifest' then lifecycle['post-generate']=index
              when 'execute-ntp-spiff-pre-bosh-deploy' then lifecycle['pre-bosh-deploy']=index
              when 'execute-ntp-post-bosh-deploy' then lifecycle['post-bosh-deploy']=index
            end
          end
        lifecycle
        }


        before do
          setup_certificates
          @stdout_str, @stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
        end

        it 'generates a post-generate task' do
          manifest_generation_task = deployment_plan.select{ |task| task['task'] == 'generate-ntp-manifest' }.first
          expect(manifest_generation_task).to include('file' => 'cf-ops-automation/concourse/tasks/generate-manifest.yml')
        end

        it 'generates a pre-bosh-deploy task' do
          pre_bosh_deploy_task = deployment_plan.select{ |task| task['task'] == 'execute-ntp-spiff-pre-bosh-deploy' }.first
          expect(pre_bosh_deploy_task).to include('file' => 'cf-ops-automation/concourse/tasks/spiff_pre_bosh_deploy.yml')
        end

        it 'generates a post-bosh task' do
          post_bosh_deploy_task = deployment_plan.select{ |task| task['task'] == 'execute-ntp-post-bosh-deploy' }.first
          expect(post_bosh_deploy_task).to include('file'=>'cf-ops-automation/concourse/tasks/post_bosh_deploy.yml')
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
      setup_certificates
      @stdout_str, @stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
    end

    it 'no error message are displayed' do
      expect(@stderr_str).to eq('')
    end

    context 'when a minimal delete depls pipeline is generated' do
      it_behaves_like 'pipeline checker', 'delete-depls-generated.yml', 'delete-depls-ref.yml'
    end

    it 'generates on-failure on each job' do
      expect(pipeline['jobs'].select{|jobs| !jobs['on_failure']}).to be_empty
    end

    it 'generates delete-deployments-review job' do
      current_job = pipeline['jobs'].select { |job| job['name'] == 'delete-deployments-review' }&.first
      current_task = current_job.select { |item| item['plan'] }['plan'].select{ |item| item['task'] == 'ntp_to_be_deleted' }&.first
      expect(current_task).to include('config')
    end

    it 'generates approve-and-delete-disabled-deployments job' do
      current_job = pipeline['jobs'].select { |job| job['name'] == 'approve-and-delete-disabled-deployments' }&.first
      current_task = current_job.select { |item| item['plan'] }['plan'].select { |item| item['task'] == 'delete_ntp' }&.first
      expect(current_task).to include('config')
    end

  end

  describe 'depls-pipeline template pre-requisite' do
    context 'when template is processed' do

      before do
      end
    end
  end

  describe 'dual deployment mode' do
    it 'handle bosh deployment using bosh cli v1'

    it 'handle bosh deployment using bosh cli v2'

  end

  describe 'file generation from template feature' do

  end


  describe 'git extented_scan_path feature' do

  end


  describe 'tfvars support feature' do

  end


  describe 'errand support feature' do

  end

end




