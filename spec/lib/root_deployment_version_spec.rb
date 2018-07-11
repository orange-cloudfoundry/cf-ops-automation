require 'rspec'
require 'root_deployment_version'

describe RootDeploymentVersion do
  let(:root_deployment_name) { 'main_depls' }
  let(:versions) do
    { RootDeploymentVersion::DEPLOYMENT_NAME => root_deployment_name, RootDeploymentVersion::STEMCELL_VERSION => 33.12 }
  end

  describe '#initialize' do
    subject { described_class.new(root_deployment_name, versions) }

    context 'when root_deployment_name is missing' do
      let(:versions) { { RootDeploymentVersion::STEMCELL_VERSION => 33.12 } }

      it 'raises an error' do
        expect { subject }.to raise_error(RuntimeError, %r{invalid #{RootDeploymentVersion::DEPLOYMENT_NAME}})
      end
    end

    context 'when stemcell version is missing' do
      let(:versions) { { RootDeploymentVersion::DEPLOYMENT_NAME => root_deployment_name } }

      it 'raises an error' do
        expect { subject }.to raise_error(RuntimeError, %r{invalid/missing #{RootDeploymentVersion::STEMCELL_VERSION}})
      end
    end

    context 'when parameters are valid' do
      it 'creates a RootDeploymentVersion object' do
        expect(subject.root_deployment_name).to eq(root_deployment_name)
      end
    end
  end

  describe '#load_file' do
    context 'when filename does not exist' do
      it 'raises an error'
    end

    context 'when filename is loaded' do
      it 'checks root_deployment_name is set using file content'
      it 'ensures object is valid'
    end

    context 'when filename does not exist' do
      it 'raises an error'
    end
  end

  describe '#init_file'
end
