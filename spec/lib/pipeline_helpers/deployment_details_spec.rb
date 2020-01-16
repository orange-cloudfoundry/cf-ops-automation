require 'rspec'
require_relative '../../../lib/pipeline_helpers'

describe PipelineHelpers::DeploymentDetails do
  let(:depl_name) { 'a-deployment' }
  let(:details) { described_class.new(options) }
  let(:options) { {} }
  let(:empty_resources) { { 'resources' => {} } }
  let(:empty_secrets) { { 'resources' => { 'secrets' => {} } } }

  describe '#initialize' do
    context 'when creating a deployment without details' do
      subject(:deployment) { described_class.new(depl_name, 'status' => 'enabled') }

      it 'creates an new deployment without details' do
        fail('NYI')
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

  describe '#local_deployment_secrets_scan?' do
    let(:local_deployment_scan) { details.local_deployment_secrets_scan? }

    context 'when no resources key exists' do
      it 'returns false as default value' do
        expect(local_deployment_scan).to be_falsey
      end
    end

    context 'when no secrets key exists' do
      let(:options) { empty_resources }

      it 'returns false as default value' do
        expect(local_deployment_scan).to be_falsey
      end
    end

    context 'when secrets key is empty' do
      let(:options) { empty_secrets }

      it 'returns false as default value' do
        expect(local_deployment_scan).to be_falsey
      end
    end

    context 'when local scan resources is enabled' do
      let(:options_yaml) { YAML.load("resources: {secrets: {local_deployment_scan: true}}")}
      let(:options) { options_yaml.to_h }

      it 'returns true' do
        expect(local_deployment_scan).to be_truthy
      end
    end

    context 'when local scan resources is disabled' do
      let(:options_yaml) { YAML.load("resources: {secrets: {local_deployment_scan: false}}")}
      let(:options) { options_yaml.to_h }

      it 'returns false' do
        expect(local_deployment_scan).to be_falsey
      end

    end
  end

  describe '#local_deployment_secrets_trigger?' do
    let(:local_deployment_trigger) { details.local_deployment_secrets_trigger? }

    context 'when no resources key exists' do
      it 'returns true as default value' do
        expect(local_deployment_trigger).to be_truthy
      end
    end

    context 'when no secrets key exists' do
      let(:options) { empty_resources }

      it 'returns true as default value' do
        expect(local_deployment_trigger).to be_truthy
      end
    end

    context 'when secrets key is empty' do
      let(:options) { empty_secrets }

      it 'returns true as default value' do
        expect(local_deployment_trigger).to be_truthy
      end
    end

    context 'when local scan resources is enabled' do
      let(:options_yaml) { YAML.load("resources: {secrets: {local_deployment_trigger: true}}")}
      let(:options) { options_yaml.to_h }

      it 'returns true' do
        expect(local_deployment_trigger).to be_truthy
      end
    end

    context 'when local scan resources is disabled' do
      let(:options_yaml) { YAML.load("resources: {secrets: {local_deployment_trigger: false}}")}
      let(:options) { options_yaml.to_h }

      it 'returns false' do
        expect(local_deployment_trigger).to be_falsey
      end

    end

  end


end
