require 'rspec'
require_relative '../../../lib/pipeline_helpers'

describe PipelineHelpers::DeploymentDetails do
  let(:depl_name) { 'a-deployment' }
  let(:details) { described_class.new(depl_name, options) }
  let(:options) { {} }
  let(:empty_resources) { { 'resources' => {} } }
  let(:empty_secrets) { { 'resources' => { 'secrets' => {} } } }

  describe '#initialize' do
    context 'when creating a deployment without details' do
      it 'creates an new deployment without details' do
        expect(details.deployment_name).to eq(depl_name)
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
      let(:options_yaml) { YAML.load("resources: {secrets: {local_deployment_scan: true}}") }
      let(:options) { options_yaml.to_h }

      it 'returns true' do
        expect(local_deployment_scan).to be_truthy
      end
    end

    context 'when local scan resources is disabled' do
      let(:options_yaml) { YAML.load("resources: {secrets: {local_deployment_scan: false}}") }
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


describe PipelineHelpers::BoshDeploymentDetails do
  subject(:bosh_deployment_details) { described_class.new(depl_name, options) }

  let(:depl_name) { 'a-deployment' }
  let(:options) { {} }
  let(:empty_resources) { { 'resources' => {} } }
  let(:empty_secrets) { { 'resources' => { 'secrets' => {} } } }

  describe '#initialize' do
    context 'when creating a deployment without details' do
      it 'creates an new BoshDeploymentDetails without details' do
        expect(bosh_deployment_details.deployment_name).to eq(depl_name)
      end
    end
  end

  describe '.cleanup?' do
    subject(:cleanup) { bosh_deployment_details.cleanup? }

    context 'when value is not set' do
      it 'is enabled by default' do
        expect(cleanup).to be true
      end
    end

    context 'when value is disabled' do
      let(:options) { { 'cleanup' => false } }

      it 'is disabled' do
        expect(cleanup).to be false
      end
    end
  end

  describe '.no_redact?' do
    subject(:no_redact) { bosh_deployment_details.no_redact? }

    context 'when value is not set' do
      it 'is disabled by default' do
        expect(no_redact).to be false
      end
    end

    context 'when value is enabled' do
      let(:options) { { 'no_redact' => true } }

      it 'is enabled' do
        expect(no_redact).to be true
      end
    end
  end

  describe '.dry_run?' do
    subject(:dry_run) { bosh_deployment_details.dry_run? }

    context 'when value is not set' do
      it 'is disabled by default' do
        expect(dry_run).to be false
      end
    end

    context 'when value is enabled' do
      let(:options) { { 'dry_run' => true } }

      it 'is enabled' do
        expect(dry_run).to be true
      end
    end
  end

  describe '.fix?' do
    subject(:fix) { bosh_deployment_details.fix? }

    context 'when value is not set' do
      it 'is disabled by default' do
        expect(fix).to be false
      end
    end

    context 'when value is enabled' do
      let(:options) { { 'fix' => true } }

      it 'is enabled' do
        expect(fix).to be true
      end
    end
  end

  describe '.recreate?' do
    subject(:recreate) { bosh_deployment_details.recreate? }

    context 'when value is not set' do
      it 'is disabled by default' do
        expect(recreate).to be false
      end
    end

    context 'when value is enabled' do
      let(:options) { { 'recreate' => true } }

      it 'is enabled' do
        expect(recreate).to be true
      end
    end
  end

  describe 'skip_drain?' do
    subject(:skip_drain) { bosh_deployment_details.skip_drain? }

    context 'when value is not set' do
      it 'is disabled by default' do
        expect(skip_drain).to be false
      end
    end

    context 'when value is nil' do
      let(:options) { { 'skip_drain' => nil } }

      it 'is disabled' do
        expect(skip_drain).to be false
      end
    end

    context 'when value is empty' do
      let(:options) { { 'skip_drain' => [] } }

      it 'is disabled' do
        expect(skip_drain).to be false
      end
    end

    context 'when value is enabled' do
      let(:instances_group) { %w[web worker] }
      let(:options) { { 'skip_drain' => instances_group } }

      it 'is enabled' do
        expect(skip_drain).to be true
      end
    end
  end

  describe 'max_in_flight?' do
    subject(:max_in_flight) { bosh_deployment_details.max_in_flight? }

    context 'when value is not set' do
      it 'is disabled by default' do
        expect(max_in_flight).to be false
      end
    end

    context 'when value is nil' do
      let(:options) { { 'max_in_flight' => nil } }

      it 'is disabled' do
        expect(max_in_flight).to be false
      end
    end

    context 'when value is empty' do
      let(:options) { { 'max_in_flight' => 0 } }

      it 'is disabled' do
        expect(max_in_flight).to be false
      end
    end

    context 'when value is enabled' do
      let(:options) { { 'max_in_flight' => 10 } }

      it 'is enabled' do
        expect(max_in_flight).to be true
      end
    end
  end
end

describe PipelineHelpers::GitDeploymentDetails do
  subject(:git_deployment_details) { described_class.new(depl_name, options) }

  let(:depl_name) { 'a-deployment' }
  let(:options) { {} }
  let(:empty_resources) { { 'resources' => {} } }
  let(:empty_secrets) { { 'resources' => { 'secrets' => {} } } }

  describe '#initialize' do
    context 'when creating a deployment without details' do
      it 'creates an new GitDeploymentDetails without details' do
        expect(git_deployment_details.deployment_name).to eq(depl_name)
      end
    end
  end

  describe '.submodule_recursive' do
    subject(:submodule_recursive) { git_deployment_details.submodule_recursive }

    let(:default_value) { "false" }

    context 'when value is not set' do
      it 'returns default_value as string' do
        expect(submodule_recursive).to eq(default_value).and be_a(String)
      end
    end

    context 'when value is set as string' do
      let(:options) { { 'submodule_recursive' => "false" } }

      it 'return the value as string' do
        expect(submodule_recursive).to eq('false').and be_a(String)
      end
    end

    context 'when value is set as boolean' do
      let(:options) { { 'submodule_recursive' => true } }

      it 'return the value as string' do
        expect(submodule_recursive).to eq('true').and be_a(String)
      end
    end

  end
  describe '.depth' do
    subject(:current_depth) { git_deployment_details.depth }

    let(:default_value) { 0 }

    context 'when value is not set' do
      it 'returns default_value' do
        expect(current_depth).to eq(default_value)
      end
    end

    context 'when value is negative' do
      let(:options) { { 'depth' => -5 } }

      it 'returns default_value' do
        expect(current_depth).to eq(default_value)
      end
    end

    context 'when value is set' do
      let(:options) { { 'depth' => 1024 } }

      it 'return the value' do
        expect(current_depth).to eq(1024)
      end
    end
  end

  describe '.depth?' do
    subject(:current_depth) { git_deployment_details.depth? }

    context 'when value is not set' do
      it 'is disabled by default' do
        expect(current_depth).to be false
      end
    end

    context 'when value is nil' do
      let(:options) { { 'depth' => nil } }

      it 'is disabled' do
        expect(current_depth).to be false
      end
    end

    context 'when value is zero' do
      let(:options) { { 'depth' => 0 } }

      it 'is enabled' do
        expect(current_depth).to be true
      end
    end

    context 'when value is enabled' do
      let(:options) { { 'depth' => 10 } }

      it 'is enabled' do
        expect(current_depth).to be true
      end
    end
  end
end
