require 'rspec'
require 'fileutils'
require_relative '../../lib/directory_initializer'

describe DirectoryInitializer do
  let(:root_deployment_name) { nil }
  let(:secrets_dir) { nil }
  let(:template_dir) { nil }

  after do
    FileUtils.rm_rf(secrets_dir) unless secrets_dir.nil?
    FileUtils.rm_rf(template_dir) unless template_dir.nil?
  end

  subject { described_class.new root_deployment_name,secrets_dir,template_dir}
  describe '#setup_secrets!' do
    let(:root_deployment_name) { 'dummy-depls' }
    let(:secrets_dir) { Dir.mktmpdir }
    let(:template_dir) { Dir.mktmpdir }

    it 'initialize directory structure for secrets' do
      subject.setup_secrets!
      expect(Dir.exist? "#{secrets_dir}/shared").to be_truthy
      expect(Dir.exist? "#{secrets_dir}/#{root_deployment_name}/secrets").to be_truthy
      expect(File.exist? "#{secrets_dir}/#{root_deployment_name}/secrets/secrets.yml").to be_truthy
      expect(File.exist? "#{secrets_dir}/#{root_deployment_name}/secrets/meta.yml").to be_truthy
      expect(File.exist? "#{secrets_dir}/#{root_deployment_name}/ci-deployment-overview.yml").to be_truthy
    end
  end

  describe '#setup_templates!' do
    let(:root_deployment_name) { 'dummy-depls' }
    let(:secrets_dir) { Dir.mktmpdir }
    let(:template_dir) { Dir.mktmpdir }

    it 'initialize directory structure for paas-template' do
      subject.setup_templates!
      expect(Dir.exist? "#{template_dir}/#{root_deployment_name}").to be_truthy
      expect(Dir.exist? "#{template_dir}/#{root_deployment_name}/template").to be_truthy
      expect(File.exist? "#{template_dir}/#{root_deployment_name}/template/deploy.sh").to be_truthy
      expect(File.exist? "#{template_dir}/#{root_deployment_name}/template/cloud-config-tpl.yml").to be_truthy
      expect(File.exist? "#{template_dir}/#{root_deployment_name}/template/runtime-config-tpl.yml").to be_truthy
      expect(File.exist? "#{template_dir}/#{root_deployment_name}/#{root_deployment_name}-versions.yml").to be_truthy

      # expect(File.exist? "#{template_dir}/.gitmodule").to be_truthy

    end
  end
end