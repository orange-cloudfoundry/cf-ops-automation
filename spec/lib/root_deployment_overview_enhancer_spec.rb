require 'rspec'
require 'tmpdir'
require_relative '../../lib/root_deployment_overview_enhancer'

describe RootDeploymentOverviewEnhancer do
  subject(:enhancer) { described_class.new(root_deployment_name, overview, versions) }

  let(:root_deployment_name) { 'main_depls' }

  describe '.initialize' do
    let(:versions) { { dummy: 'versions' } }
    let(:overview) { { dummy: 'overview' } }

    context 'when overview is nil' do
      let(:overview) { nil }

      it 'raises an error ' do
        expect { enhancer }.to raise_error(RuntimeError, "invalid root_deployment_overview")
      end
    end

    context 'when overview is empty' do
      let(:overview) { {} }

      it 'creates a valid object' do
        expect(enhancer).not_to be_nil
      end
    end

    context 'when versions is nil' do
      let(:versions) { nil }

      it 'raises an error' do
        expect { enhancer }.to raise_error(RuntimeError, "invalid root_deployment_versions")
      end
    end

    context 'when versions is empty' do
      let(:versions) { {} }

      it 'creates a valid object' do
        expect(enhancer).not_to be_nil
      end
    end
  end

  describe '.enhance' do

    context 'when a enable-deployment.yml is found without a matching deployment-dependencies.yml' do
      let(:overview) { load_fixture(File.join('root-deployment', 'ops-depls-overview.yml')) }
      let(:versions) { load_fixture(File.join('version-reference', 'ops-depls-loaded-versions.yml')) }
      let(:expected_enhanced_overview) { load_fixture(File.join('root-deployment-overview-enhancer', 'expected-ops-depls.yml')) }

      it 'raises an error' do
        expect(enhancer.enhance).to match(expected_enhanced_overview)
      end
    end
  end
end

