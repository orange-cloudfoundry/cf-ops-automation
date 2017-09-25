require 'rspec'
require 'yaml'
require 'fileutils'
require_relative '../../lib/directory_initializer'
require_relative '../../lib/root_deployment_version'

describe DirectoryInitializer do

  subject { described_class.new root_deployment_name, secrets_dir, template_dir }

  let(:root_deployment_name) { nil }
  let(:secrets_dir) { Dir.mktmpdir('secrets-') }
  let(:template_dir) { Dir.mktmpdir( 'templates-' ) }



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

      it 'create a shared dir' do
        expect( Dir.exist?("#{secrets_dir}/shared") ).to be_truthy
      end

      it 'create a ci-deployment-overview.yml in new root deployment' do
        expect(File.exist?("#{secrets_dir}/#{root_deployment_name}/ci-deployment-overview.yml")).to be_truthy
      end

      it 'create meta and secrets files in new root deployment' do
        expect(Dir.exist?("#{secrets_dir}/#{root_deployment_name}/secrets")).to be_truthy
        expect(File.exist?("#{secrets_dir}/#{root_deployment_name}/secrets/secrets.yml")).to be_truthy
        expect(File.exist?("#{secrets_dir}/#{root_deployment_name}/secrets/meta.yml")).to be_truthy
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