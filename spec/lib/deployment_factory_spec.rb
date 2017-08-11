require 'rspec'
require_relative '../../lib/deployment_factory'

describe DeploymentFactory do

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

    context 'when data is empty ' do
      it 'an empty hash is return'
    end

  end



end