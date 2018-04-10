require 'rspec'
require 'yaml'
require 'fileutils'
require 'tmpdir'
require_relative '../../lib/directory_initializer'
require_relative '../../lib/root_deployment_version'

describe DirectoryInitializer do

  subject { described_class.new root_deployment_name, secrets_dir, template_dir }

  let(:root_deployment_name) { nil }
  let(:secrets_dir) { Dir.mktmpdir('secrets-') }
  let(:template_dir) { Dir.mktmpdir('templates-') }



  after(:each) do
    FileUtils.rm_rf(secrets_dir) unless secrets_dir.nil?
    FileUtils.rm_rf(template_dir) unless template_dir.nil?
  end


  describe '#setup_secrets!' do
    let(:root_deployment_name) { 'dummy-depls' }

    context 'when secrets directory structure is initialized' do

      before do
        subject.setup_secrets!
      end

      context 'when shared_dir structure is valid' do
        it 'creates a shared dir' do
          expect(Dir).to exist("#{secrets_dir}/shared")
        end

        it 'contains a secrets.yml' do
          expect(File).to exist("#{secrets_dir}/shared/secrets.yml")
        end

        it 'contains a meta.yml' do
          expect(File).to exist("#{secrets_dir}/shared/meta.yml")
        end

        it 'shared/secrets.yml is valid' do

          shared_secrets = YAML.load_file("#{secrets_dir}/shared/secrets.yml")
          # YAML.load_file returns false if file is empty.

          expect(shared_secrets).to be_falsey
        end

      end


      it 'create a ci-deployment-overview.yml in new root deployment' do
        expect(File).to exist("#{secrets_dir}/#{root_deployment_name}/ci-deployment-overview.yml")
      end
    end

    context 'when files are generated with default value' do
      it 'ci-deployment-overview.yml is valid' do
        subject.setup_secrets!

        generated_ci_overview = YAML.load_file("#{secrets_dir}/#{root_deployment_name}/ci-deployment-overview.yml")

        b = binding
        b.local_variable_set(:depls, 'dummy-depls')
        reference = YAML.load(ERB.new(File.read("#{File.dirname __FILE__}/fixtures/ci-deployment-overview.yml.erb"), 0, '<>').result(b))


        expect(generated_ci_overview).to eq(reference)#, "#{secrets_dir}/#{root_deployment_name}/ci-deployment-overview.yml"
      end
    end
  end

  describe '#setup_templates!' do
    let(:root_deployment_name) { 'dummy-depls' }
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

    context 'when files are generated with default value' do

      it '<root_deployment>-versions.yml is valid' do
        subject.setup_templates!

        versions = RootDeploymentVersion.load_file("#{template_dir}/#{root_deployment_name}/#{root_deployment_name}-versions.yml")
        expect(versions).not_to be_nil
      end
    end
  end

  describe 'add_deployment' do
    let(:root_deployment_name) { 'dummy-depls' }
    let(:my_deployment_name) { 'autosleep' }
    let(:init){
      subject.setup_templates!
      subject.setup_secrets!
    }

    before do
      init
      subject.add_deployment(my_deployment_name)
    end

    it 'creates a deployment specific template dir' do
      expect(Dir).to exist("#{template_dir}/#{root_deployment_name}/#{my_deployment_name}")
    end

    it 'creates a deployment specific secrets dir' do
      expect(Dir).to exist("#{secrets_dir}/#{root_deployment_name}/#{my_deployment_name}")
    end

    it 'creates a deployment specific secrets/secrets dir' do
      expect(Dir).to exist("#{secrets_dir}/#{root_deployment_name}/#{my_deployment_name}/secrets")
    end

    it 'creates a deployment specific secrets/meta.yml file' do
      expect(File).to exist("#{secrets_dir}/#{root_deployment_name}/#{my_deployment_name}/secrets/meta.yml")
    end

    it 'creates a deployment specific secrets/secrets.yml file' do
      expect(File).to exist("#{secrets_dir}/#{root_deployment_name}/#{my_deployment_name}/secrets/secrets.yml")
    end

    it 'creates a deployment specific secrets/meta.yml that is valid' do
      secrets_meta = YAML.load_file("#{secrets_dir}/#{root_deployment_name}/#{my_deployment_name}/secrets/meta.yml")
      expect(secrets_meta).to be_falsey
    end

    it 'creates a deployment specific secrets/secrets.yml that is valid' do
      secrets_secrets = YAML.load_file("#{secrets_dir}/#{root_deployment_name}/#{my_deployment_name}/secrets/secrets.yml")
      expect(secrets_secrets).to be_falsey
    end
  end

  describe '#enable_deployment' do
    let(:root_deployment_name) { 'dummy-depls' }
    let(:my_deployment_name) { 'autosleep' }
    let(:init){
      subject.setup_templates!
      subject.setup_secrets!
    }

    context 'when a deployment exists' do
      before do
        init
        subject.add_deployment(my_deployment_name)
      end

      it 'adds an enable marker' do
        subject.enable_deployment(my_deployment_name)

        expect(File).to exist "#{secrets_dir}/#{root_deployment_name}/#{my_deployment_name}/#{RootDeployment::ENABLE_DEPLOYMENT_FILENAME}"
      end

      context 'when already enabled' do
        before do
          subject.enable_deployment(my_deployment_name)
        end
        it 'does not fail' do
          subject.enable_deployment(my_deployment_name)

          expect(File).to exist "#{secrets_dir}/#{root_deployment_name}/#{my_deployment_name}/#{RootDeployment::ENABLE_DEPLOYMENT_FILENAME}"
        end
      end
    end

    context 'when a deployment does not exist' do
      before do
        init
      end

      it 'raise an error' do
        begin
          subject.enable_deployment(my_deployment_name)
          fail('shoud not be here')
        rescue => error
          expect(error).to be_a(Errno::ENOENT)
        end
      end

    end

  end

  describe '#disable_deployment' do
    let(:root_deployment_name) { 'dummy-depls' }
    let(:my_deployment_name) { 'autosleep' }
    let(:init){
      subject.setup_templates!
      subject.setup_secrets!
    }

    context 'when a deployment exists' do
      before(:each) do
        init
        subject.add_deployment(my_deployment_name)
        subject.enable_deployment(my_deployment_name)
      end

      it 'deletes the enable marker' do
        subject.disable_deployment(my_deployment_name)

        expect(File).to_not exist "#{secrets_dir}/#{root_deployment_name}/#{my_deployment_name}/#{RootDeployment::ENABLE_DEPLOYMENT_FILENAME}"
      end

    end

    context 'when a deployment does not exist' do
      before(:each) do
        init
      end

      it 'does nothing' do
          subject.disable_deployment(my_deployment_name)
          expect(File).to_not exist "#{secrets_dir}/#{root_deployment_name}/#{my_deployment_name}/#{RootDeployment::ENABLE_DEPLOYMENT_FILENAME}"
      end

    end

  end
end
