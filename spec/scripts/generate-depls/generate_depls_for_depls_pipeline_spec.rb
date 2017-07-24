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


  context 'when a simple deployment is used' do
    let(:depls_name) { 'simple-depls' }
    let(:output_path) { Dir.mktmpdir }
    let(:templates_path) { "#{fixture_path}/templates" }
    let(:secrets_path) { "#{fixture_path}/secrets" }

    after do
      FileUtils.rm_rf(output_path) unless output_path.nil?
    end

    context 'when only templates dir is initialized' do
      let(:options) { "-d #{depls_name} -o #{output_path} -t #{templates_path} -p #{secrets_path} --no-dump" }

      stdout_str = stderr_str = ''
      before do
        TestHelper.create_test_root_ca "#{secrets_path}/shared/certs/internal_paas-ca/server-ca.crt"
        stdout_str, stderr_str, = Open3.capture3("#{ci_path}/scripts/generate-depls.rb #{options}")
      end

      it 'generate pipelines without deployment' do
        expect(stderr_str).to eq('')
        expect(stdout_str).to include('processing ./concourse/pipelines/template/depls-pipeline.yml.erb').and \
          include('')
      end

      # context 'when depls pipeline is checked' do
      #   it_behaves_like 'pipeline checker', 'dummy-depls-generated.yml', 'empty-depls.yml'
      # end

    end

  end

  describe 'dual deployment mode' do
    it 'handle bosh deployment using bosh cli v1' do

    end

    it 'handle bosh deployment using bosh cli v2' do

    end

  end

  describe 'file generation from template feature' do

  end


  describe 'git extented_scan_path feature' do

  end


  describe 'tfvars support feature' do

  end

  describe 'scripting lifecycle feature' do
    # if template directory contains scripts with specific name, then these scripts are executed, using the following order :
    #   1: post-generate.sh: can execute shell operation or spruce task.
    #         **Restrictions**: as the post-generation script is executed in the same docker image running spruce, no spiff is available.
    #   2: pre-bosh-deploy.sh: can execute shell operation or spiff task.
    #   3: post-bosh-deploy.sh: can execute shell operation (including curl).
  end

  describe 'errand support feature' do

  end

end




