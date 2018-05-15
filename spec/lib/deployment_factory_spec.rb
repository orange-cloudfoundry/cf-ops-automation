require 'rspec'
require_relative '../../lib/deployment_factory'

describe DeploymentFactory do
  let(:root_deployment_name) { 'main_depls' }
  let(:deployment_name) { 'my_deployment' }
  let(:config) { Config.new }
  let(:versions) do
    { 'deployment-name' => root_deployment_name, 'stemcell-version' => '10.0',
      'bosh-version' => '264.10.0',
      'bosh-openstack-cpi-release-version' => '37' }
  end

  describe '#initialize' do
    subject { described_class.new(root_deployment_name, versions, config) }

    context 'when version is valid' do
      it 'contains a stemcell version' do
        expect(subject.version_reference).to include('stemcell-version')
      end
    end

    context 'when version is invalid' do
      let(:versions) {}

      it 'raise an error about stemcell-version' do
        expect { subject }.to raise_error(RuntimeError) { |error| expect(error.message).to match('invalid version: missing stemcell version') }
      end
    end

    context 'when config is valid' do
      it 'contains a stemcell name' do
        expect(subject.stemcell_name).to eq(Config::DEFAULT_STEMCELL)
      end
    end

    context 'when config is nil' do
      let(:config) {}

      it 'complains about nil config' do
        expect { subject }.to raise_error(RuntimeError) { |error| expect(error.message).to match('invalid config: cannot be nil') }
      end
    end

    context 'when config is incomplete' do
      let(:config) { instance_double(Config) }

      it 'raises an error about stemcell-name' do
        allow(config).to receive(:stemcell_name).and_return('')

        expect { subject }.to raise_error(RuntimeError) { |error| expect(error.message).to match('invalid config: missing stemcell, expected: a config with a stemcell name defined') }
      end
    end
  end

  describe '#load_file' do
    context 'when file does not exist' do
      subject { described_class.new(root_deployment_name, versions, config).load_file 'dummy-filename.yml' }

      it 'raise an error' do
        expect { subject }.to raise_error(RuntimeError) { |error| expect(error.message).to match('file not found: dummy-filename.yml') }

      end
    end

    context 'when filename is nil ' do
      subject { described_class.new(root_deployment_name, versions, config).load_file nil }

      it 'raise an error' do
        expect { subject }.to raise_error(RuntimeError) { |error| expect(error.message).to match('invalid filename. Cannot be nil') }

      end
    end

    context 'when filename is empty ' do
      subject { described_class.new(root_deployment_name, versions, config).load_file '' }

      it 'raise an error' do
        expect { subject }.to raise_error(RuntimeError) { |error| expect(error.message).to match('file not found: ') }

      end
    end
  end

  describe '#load' do
    context 'when data is nil ' do
      let(:deployment_factory) do
        described_class.new(
            root_deployment_name,
            versions
        )
      end

      it 'raise an error' do
        expect { deployment_factory.load(nil) }.to raise_error(RuntimeError) { |error| expect(error.message).to match("invalid data. Cannot load 'nil' data") }
      end
    end

    context 'when a deployment does not have any details' do
      let(:deployment_factory) do
        described_class.new(
          root_deployment_name,
          versions
        )
      end
      let(:loaded_deployments) { deployment_factory.load('deployment' => { deployment_name => nil }) }

      it 'creates a deployment object with an empty details field' do
        expect(loaded_deployments.first).to have_attributes(name: deployment_name, details: {})
      end
    end

    context 'when a deployment is loaded' do
      let(:versions) do
        { 'deployment-name' => root_deployment_name, 'stemcell-version' => '10.0',
          'bosh-version' => '264.10.0',
          'bosh-openstack-cpi-release-version' => '37' }
      end
      let(:deployment_factory) { described_class.new(root_deployment_name, versions, config) }
      let(:loaded_deployments) { deployment_factory.load('deployment' => bosh_master_deployment) }
      let(:bosh_master_deployment) do
        my_yaml = <<~YAML
          #{deployment_name}:
            releases:
              bosh:
                base_location: https://bosh.io/d/github.com/
                repository: cloudfoundry/bosh
              bosh-openstack-cpi-release:
                base_location: https://bosh.io/d/github.com/
                repository: cloudfoundry-incubator/bosh-openstack-cpi-release
        YAML
        YAML.safe_load(my_yaml)
      end

      it 'creates an enhanced deployment' do
        expect(loaded_deployments.first).to have_attributes(name: deployment_name, details: include('stemcells' => { 'bosh-openstack-kvm-ubuntu-trusty-go_agent' => {} }))
      end
    end
  end
end
