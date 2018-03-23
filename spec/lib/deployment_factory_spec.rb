require 'rspec'
require_relative '../../lib/deployment_factory'

describe DeploymentFactory do
  let(:root_deployment_name) { 'main_depls' }
  let(:deployment_name) { 'my_deployment' }

  describe '#initialize' do
    it 'validates param'

    context 'when version is invalid' do
      it 'deployment-name'
      it 'stemcell-version'
      it 'stemcell-name'
    end
  end

  describe '#load_file' do
    context 'when file does not exist' do
      it 'raise an error'
    end

    context 'when filename is nil ' do
      it 'raise an error'
    end

    context 'when filename is empty ' do
      it 'raise an error'
    end
  end

  describe '#load' do
    context 'when data is nil ' do
      it 'raise an error'
    end

    context 'when a deployment does not have any details' do
      let(:deployment_factory) do
        described_class.new(
          root_deployment_name,
          nil
        )
      end
      let(:loaded_deployments) { deployment_factory.load('deployment' => { deployment_name => nil }) }

      it 'creates a deployment object with an empty details field' do
        expect(loaded_deployments.first).to have_attributes(name: deployment_name, details: {})
      end
    end
  end
end
