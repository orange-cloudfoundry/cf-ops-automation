require 'rspec'
require 'deployment_factory'

describe DeploymentFactory do
  let(:root_deployment_name) { 'main_depls' }
  let(:deployment_name) { 'my_deployment' }
  let(:config) { instance_double(Config) }
  let(:versions) do
    { 'deployment-name' => root_deployment_name, 'stemcell-version' => '10.0',
      'bosh-version' => '264.10.0',
      'bosh-openstack-cpi-release-version' => '37' }
  end

  before do
    allow(config).to receive(:stemcell_name).and_return(Config.new.stemcell_name)
    allow(config).to receive(:iaas_type).and_return(Config.new.iaas_type)
    allow(config).to receive(:bosh_options).and_return(Config.new.bosh_options)
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
        expect { subject }.to raise_error(RuntimeError, 'invalid version: missing stemcell version')
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
        expect { subject }.to raise_error(RuntimeError, 'invalid config: cannot be nil')
      end
    end

    context 'when config is incomplete' do
      let(:config) { instance_double(Config) }

      it 'raises an error about stemcell-name' do
        allow(config).to receive(:stemcell_name).and_return('')

        expect { subject }.to raise_error(RuntimeError, /invalid config: missing stemcell, expected: a config with a stemcell name defined/)
      end
    end
  end

  describe '#load_files' do
    let(:deployment_factory) { described_class.new(root_deployment_name, versions, config) }
    let(:generic_deployment) { [Deployment.default(deployment_name)] }
    let(:loaded_deployment) { deployment_factory.load_files('dummy-filename.yml') }
    let(:my_deployment) { loaded_deployment.first }
    let(:current_profiles) { %w[no_profile_files] }
    let(:current_iaas_type) { 'a_custom_iaas' }

    before do
      allow(config).to receive(:iaas_type).and_return(current_iaas_type)
      allow(config).to receive(:profiles).and_return(current_profiles)
    end

    context 'when no profiles and no iaas_type files exist' do
      let(:default_bosh_options) { { 'bosh-options' => { 'cleanup' => true, 'dry_run' => false, 'fix' => false, 'max_in_flight' => nil, 'no_redact' => false, 'recreate' => false, 'skip_drain' => [] } } }

      before do
        allow(deployment_factory).to receive(:load_file).with('dummy-filename.yml').and_return(generic_deployment)
        allow(File).to receive(:exist?).with("dummy-filename-#{current_iaas_type}.yml").and_return(false)
        allow(File).to receive(:exist?).with("dummy-filename-#{current_profiles.first}.yml").and_return(false)
      end

      it 'loads deployment-dependencies.yml' do
        expect(my_deployment.details).to eq(Deployment.default_details.merge(default_bosh_options))
      end
    end

    context 'when two profiles exists' do
      let(:current_profiles) { %w[profile-1 profile-2] }
      let(:generic_deployment) do
        content = <<~YAML
          bosh-options:
            cleanup: false
          releases:
            my-bosh-release:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry/my-bosh-release
            overridden-bosh-release:
              base_location: to-be-overriden
              repository: to-be-overriden
        YAML
        details = YAML.safe_load(content)
        [Deployment.new(deployment_name, Deployment.default_details.merge(details))]
      end
      let(:profile_1_deployment) do
        content = <<~YAML
          bosh-options:
            dry_run: true
            recreate: true
          profile-1-type: true
          profile-1-property: true
          releases:
            overridden-bosh-release:
              base_location: https://bosh.io/d/github.com/
              repository: profile-1/overridden-bosh-release
            profile-1-bosh-release:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry/p1-bosh-release
        YAML
        details = YAML.safe_load(content)
        [Deployment.new('profile-1-override', details)]
      end
      let(:profile_2_deployment) do
        content = <<~YAML
          bosh-options:
            dry_run: false
          profile-2-type: true
          profile-1-property: false
          releases:
            overridden-bosh-release:
              base_location: https://bosh.io/d/github.com/
              repository: profile-2/overridden-bosh-release
            profile-2-bosh-release:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry/p2-bosh-release
        YAML
        details = YAML.safe_load(content)
        [Deployment.new('profile-1-override', details)]
      end
      let(:expected_details) do
        {
          'bosh-options' => { 'cleanup' => false, 'dry_run' => false, 'recreate' => true, 'fix' => false, 'max_in_flight' => nil, 'no_redact' => false, 'skip_drain' => [] },
          'profile-1-type' => true,
          'profile-1-property' => false,
          'profile-2-type' => true,
          'releases' => {
            'profile-1-bosh-release' => { 'base_location' => 'https://bosh.io/d/github.com/', 'repository' => 'cloudfoundry/p1-bosh-release' },
            'profile-2-bosh-release' => { 'base_location' => 'https://bosh.io/d/github.com/', 'repository' => 'cloudfoundry/p2-bosh-release' },
            'my-bosh-release' => { 'base_location' => 'https://bosh.io/d/github.com/', 'repository' => 'cloudfoundry/my-bosh-release' },
            'overridden-bosh-release' => { 'base_location' => 'https://bosh.io/d/github.com/', 'repository' => 'profile-2/overridden-bosh-release' }
          },
          'stemcells' => {}
        }
      end

      before do
        allow(deployment_factory).to receive(:load_file).with('dummy-filename.yml').and_return(generic_deployment)

        allow(File).to receive(:exist?).with("dummy-filename-#{current_iaas_type}.yml").and_return(false)

        allow(File).to receive(:exist?).with("dummy-filename-profile-1.yml").and_return(true)
        allow(deployment_factory).to receive(:load_file).with('dummy-filename-profile-1.yml').and_return(profile_1_deployment)
      end

      it 'loads and merges all deployment dependencies files' do
        allow(File).to receive(:exist?).with("dummy-filename-profile-2.yml").and_return(true)
        allow(deployment_factory).to receive(:load_file).with('dummy-filename-profile-2.yml').and_return(profile_2_deployment)

        expect(my_deployment.details).to eq(expected_details)
      end
    end

    context 'when iaas file exists without profiles' do
      let(:current_iaas_type) { 'openstack' }
      let(:generic_deployment) do
        content = <<~YAML
          bosh-options:
            recreate: true
          releases:
            my-bosh-release:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry/my-bosh-release
            overridden-bosh-release:
              base_location: to-be-overriden
              repository: to-be-overriden
        YAML
        details = YAML.safe_load(content)
        [Deployment.new(deployment_name, Deployment.default_details.merge(details))]
      end
      let(:iaas_deployment) do
        content = <<~YAML
          bosh-options:
            fix: true
          iaas-type: true
          releases:
            bosh-openstack-cpi-release:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry-incubator/bosh-openstack-cpi-release 
            overridden-bosh-release:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry/overridden-bosh-release
        YAML
        details = YAML.safe_load(content)
        [Deployment.new('iaas-override', details)]
      end
      let(:expected_details) do
        { 'bosh-options' => { 'recreate' => true, 'fix' => true, 'cleanup' => true, 'dry_run' => false, 'no_redact' => false, 'skip_drain' => [], 'max_in_flight' => nil },
          'iaas-type' => true,
          'releases' => {
              'my-bosh-release' => {'base_location' => 'https://bosh.io/d/github.com/', 'repository' => 'cloudfoundry/my-bosh-release'},
              'overridden-bosh-release' => {'base_location' => 'https://bosh.io/d/github.com/', 'repository' => 'cloudfoundry/overridden-bosh-release'},
              'bosh-openstack-cpi-release' => {'base_location' => 'https://bosh.io/d/github.com/', 'repository' => 'cloudfoundry-incubator/bosh-openstack-cpi-release'}
          },
          'stemcells' => {} }
      end

      it 'merge deployment-dependencies with iaas file' do
        allow(deployment_factory).to receive(:load_file).with('dummy-filename.yml').and_return(generic_deployment)
        allow(deployment_factory).to receive(:load_file).with('dummy-filename-openstack.yml').and_return(iaas_deployment)
        allow(File).to receive(:exist?).with("dummy-filename-#{config.iaas_type}.yml").and_return(true)
        allow(File).to receive(:exist?).with("dummy-filename-#{config.profiles.first}.yml").and_return(false)

        expect(my_deployment.details).to eq(expected_details)
        expect(my_deployment.name).to eq(deployment_name)
      end
    end

    context 'when iaas and profiles files exist' do
      let(:generic_deployment) do
        content = <<~YAML
          releases:
            my-bosh-release:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry/my-bosh-release
            overridden-bosh-release:
              base_location: to-be-overriden
              repository: to-be-overriden
        YAML
        details = YAML.safe_load(content)
        [Deployment.new(deployment_name, Deployment.default_details.merge(details))]
      end
      let(:iaas_deployment) do
        content = <<~YAML
          bosh-options:
            cleanup: false
            dry_run: true
          iaas-type: true
          releases:
            bosh-openstack-cpi-release:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry-incubator/bosh-openstack-cpi-release
            overridden-bosh-release:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry/overridden-bosh-release
        YAML
        details = YAML.safe_load(content)
        [Deployment.new('iaas-override', details)]
      end
      let(:profile_1_deployment) do
        content = <<~YAML
          bosh-options:
            dry_run: false
            no_redact: true
          profile-1-type: true
          releases:
            bosh-openstack-cpi-release:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry-incubator/bosh-openstack-cpi-release
            overridden-bosh-release:
              base_location: https://bosh.io/d/github.com/
              repository: profile-1/overridden-bosh-release
            profile-1-bosh-release:
              base_location: https://bosh.io/d/github.com/
              repository: cloudfoundry/p1-bosh-release
        YAML
        details = YAML.safe_load(content)
        [Deployment.new('profile-1-override', details)]
      end

      let(:expected_details) do
        {
          'bosh-options' => { 'cleanup' => false, 'dry_run' => false, 'fix' => false, 'max_in_flight' => nil, 'no_redact' => true, 'recreate' => false, 'skip_drain' => [] },
          'profile-1-type' => true,
          'iaas-type' => true,
          'releases' => {
             'profile-1-bosh-release' => { 'base_location' => 'https://bosh.io/d/github.com/', 'repository' => 'cloudfoundry/p1-bosh-release' },
             'my-bosh-release' => { 'base_location' => 'https://bosh.io/d/github.com/', 'repository' => 'cloudfoundry/my-bosh-release' },
             'overridden-bosh-release' => { 'base_location' => 'https://bosh.io/d/github.com/', 'repository' => 'profile-1/overridden-bosh-release' },
             'bosh-openstack-cpi-release' => { 'base_location' => 'https://bosh.io/d/github.com/', 'repository' => 'cloudfoundry-incubator/bosh-openstack-cpi-release' }
          },
          'stemcells' => {}
        }
      end
      let(:current_profiles) { %w[profile-1] }

      before do
        allow(config).to receive(:iaas_type).and_return('openstack')
        allow(deployment_factory).to receive(:load_file).with('dummy-filename-openstack.yml').and_return(iaas_deployment)
        allow(config).to receive(:profiles).and_return(current_profiles)
        allow(File).to receive(:exist?).with("dummy-filename-#{current_profiles.first}.yml").and_return(true)
        allow(deployment_factory).to receive(:load_file).with('dummy-filename-profile-1.yml').and_return(profile_1_deployment)
      end

      it 'merge deployment-dependencies with iaas file and then with profiles' do
        allow(deployment_factory).to receive(:load_file).with('dummy-filename.yml').and_return(generic_deployment)
        allow(File).to receive(:exist?).with("dummy-filename-#{config.iaas_type}.yml").and_return(true)

        expect(my_deployment.details).to eq(expected_details)
      end
    end
  end


  describe '#load_file' do
    context 'when file does not exist' do
      subject { described_class.new(root_deployment_name, versions, config).load_file 'dummy-filename.yml' }

      it 'raise an error' do
        expect { subject }.to raise_error(RuntimeError, /file not found: dummy-filename.yml/)
      end
    end

    context 'when filename is nil ' do
      subject { described_class.new(root_deployment_name, versions, config).load_file nil }

      it 'raise an error' do
        expect { subject }.to raise_error(RuntimeError, /invalid filename. Cannot be empty/)
      end
    end

    context 'when filename is empty ' do
      subject { described_class.new(root_deployment_name, versions, config).load_file '' }

      it 'raise an error' do
        expect { subject }.to raise_error(RuntimeError, /invalid filename. Cannot be empty/)
      end
    end
  end

  describe '#load' do
    let(:deployment_factory) { described_class.new(root_deployment_name, versions) }

    context 'when data is not set' do
      it 'raise an error' do
        expect { deployment_factory.load(deployment_name) }.
          to raise_error(RuntimeError, /invalid data. Cannot load empty data/)
      end
    end

    context 'when data is invalid' do
      let(:invalid_data) { YAML.load('invalid: true').to_s }

      it 'raise an error' do
        expect { deployment_factory.load(deployment_name, invalid_data) }.
          to raise_error(RuntimeError, /Invalid data. Missing root: 'deployment'/)
      end
    end

    context 'when deployment_name is not set' do
      it 'raise an error' do
        expect { deployment_factory.load }.to raise_error(RuntimeError, /invalid deployment_name. Cannot be empty/)
      end
    end

    context 'when deployment_name does not match yaml content' do
      let(:ntp_deployment_dependencies_content) { { 'deployment' => { 'ntp' => Deployment.default_details } } }

      it 'raise an error' do
        expect { deployment_factory.load('my-deployment', ntp_deployment_dependencies_content) }.to raise_error(RuntimeError, /Invalid deployment_name: expected <my-deployment> or <bosh-deployment> - Found <ntp>/)
      end
    end

    context 'when deployment dependencies yaml follows COA conventions' do
      let(:generic_deployment_dependencies_content) { { 'deployment' => { 'bosh-deployment' => Deployment.default_details } } }
      let(:deployment_name) { 'my-deployment' }
      let(:loaded_deployment) { deployment_factory.load(deployment_name, generic_deployment_dependencies_content) }
      let(:my_deployment) { loaded_deployment.first }

      it 'loads my_deployment' do
        expect(my_deployment.name).to eq(deployment_name)
      end
    end

    context 'when a deployment does not have any details' do
      let(:loaded_deployments) { deployment_factory.load(deployment_name, 'deployment' => { deployment_name => nil }) }

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
      let(:loaded_deployments) { deployment_factory.load(deployment_name, 'deployment' => bosh_master_deployment) }
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
        expect(loaded_deployments.first).to have_attributes(name: deployment_name, details: include('stemcells' => { 'bosh-openstack-kvm-ubuntu-xenial-go_agent' => {} }))
      end
    end
  end
end
