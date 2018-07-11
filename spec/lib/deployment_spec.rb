require 'rspec'
require 'deployment'

describe Deployment do
  let(:depl_name) { 'a-deployment' }

  describe '#initialize' do
    it 'creates an new deployment without details'
  end

  describe '#enabled?' do
    context 'when details contains a status set to enabled' do
      subject { described_class.new(depl_name, 'status' => 'enabled') }

      it 'return true' do
        expect(subject).to be_enabled
      end
    end

    context 'when details does not contains any status set' do
      subject { described_class.new(depl_name) }

      it 'return false' do
        expect(subject).not_to be_enabled
      end
    end
  end

  describe '#disabled?' do
    context 'when details contains a status set to disabled' do
      subject { described_class.new(depl_name, 'status' => 'disabled') }

      it 'return true' do
        expect(subject).to be_disabled
      end
    end

    context 'when details does not contains any status set' do
      subject { described_class.new(depl_name) }

      it 'return true' do
        expect(subject).to be_disabled
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
