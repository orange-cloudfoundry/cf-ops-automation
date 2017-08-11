require 'rspec'
require_relative '../../lib/root_deployment_version'

describe RootDeploymentVersion do

  let(:root_deployment_name) { 'main_depls' }
  let(:versions) { { RootDeploymentVersion::DEPLOYMENT_NAME => root_deployment_name,
                     RootDeploymentVersion::STEMCELL_NAME => 'openstack',
                     RootDeploymentVersion::STEMCELL_VERSION => 33.12 } }

  describe '#initialize' do
    context 'when root_deployment_name is invalid' do

      it 'raises an error'
    end

    context 'when stemcell name is missing' do

      it 'raises an error'
    end

    context 'when stemcell version is missing' do

      it 'raises an error'
    end

    context 'when parameters are valid' do
      let(:sub) {RootDeploymentVersion.new(root_deployment_name, versions)}
      it 'creates a RootDeploymentVersion object' do
        expect(sub.root_deployment_name).to eq(root_deployment_name)
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

  describe '#init_file' do


  end

end