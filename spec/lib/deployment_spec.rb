require 'rspec'
require 'deployment'

describe Deployment do
  let(:depl_name) { 'a-deployment' }

  describe '#initialize' do
    context 'when creating a deployment without details' do
      subject(:deployment) { described_class.new(depl_name) }

      it 'creates an new deployment without details' do
        expect(deployment.details).to be_empty
      end
    end

    context 'when creating a deployment' do
      subject(:deployment) { described_class.new(depl_name, details) }

      let(:details) { {key_1: 'value', key_2: 'value'} }

      it 'creates an new deployment with details' do
        expect(deployment.details).to match(details)
      end
    end
  end

  describe '#enabled?' do
    context 'when details contains a status set to enabled' do
      subject(:deployment) { described_class.new(depl_name, 'status' => 'enabled') }

      it 'return true' do
        expect(deployment).to be_enabled
      end
    end

    context 'when details does not contains any status set' do
      subject(:deployment) { described_class.new(depl_name) }

      it 'return false' do
        expect(deployment).not_to be_enabled
      end
    end
  end

  describe '#disabled?' do
    context 'when details contains a status set to disabled' do
      subject(:deployment) { described_class.new(depl_name, 'status' => 'disabled') }

      it 'return true' do
        expect(deployment).to be_disabled
      end
    end

    context 'when details does not contains any status set' do
      subject(:deployment) { described_class.new(depl_name) }

      it 'return true' do
        expect(deployment).to be_disabled
      end
    end
  end

  describe '#default' do
    context 'when a name is set' do
      let(:my_default) { described_class.default('my-depls') }

      it 'returns a new deployment named my-depls' do
        expect(my_default.name).to eq('my-depls')
      end

      it 'returns a non empty details' do
        expect(my_default.details).not_to be_empty
      end

      it 'has an empty releases tag' do
        expect(my_default.details).to include('releases' => {})
      end

      it 'has a empty stemcell tag' do
        expect(my_default.details).to include('stemcells' => {})
      end
    end
  end
end
