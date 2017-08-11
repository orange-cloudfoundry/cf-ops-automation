require 'rspec'
require_relative '../../lib/root_deployment'

describe RootDeployment do

  let(:root_deployment_name) { 'main_depls' }
  let(:dependency_root_path) { 'dependency_root_path' }
  let(:enable_deployment_root_path) { 'xxx' }

  describe '#initialize' do
    it 'cannot initialize if a parameter is nil'
  end


  describe '#overview_from_hash' do

    context 'when no enable-deployment.yml found' do
      # subject(RootDeployment.new(root_deployment_name, dependency_root_path, enable_deployment_root_path))
      it 'return an empty Hash'
    end

    context 'when a enable-deployment.yml and a deployment-dependencies are found' do
      it 'return a hash with all deployment overview'
    end

    context 'when a enable-deployment.yml is found without a matching deployment-dependencies.yml' do
      it 'raises an error'
    end

    context 'when a deployment name does not match definition directory' do
      it 'raises an error'
    end


  end

end