require 'rspec'
require_relative '../../../lib/pipeline_helpers'

describe PipelineHelpers::DeploymentDetails do
  let(:details) { described_class.new(options) }
  let(:options) { {} }
  let(:empty_resources) { { 'resources' => {} } }
  let(:empty_secrets) { { 'resources' => { 'secrets' => {} } } }

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
