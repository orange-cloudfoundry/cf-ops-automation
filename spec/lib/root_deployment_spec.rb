require 'rspec'
require 'tmpdir'
require_relative '../../lib/root_deployment'
require_relative '../../lib/directory_initializer'

describe RootDeployment do
  let(:root_deployment_name) { 'main_depls' }

  let(:templates) do
    Dir.mktmpdir('templates')
  end
  let(:secrets) do
    Dir.mktmpdir('secrets')
  end

  let(:dir_init) do
    tf = 'terraform-config'
    init = DirectoryInitializer.new(root_deployment_name, secrets, templates, tf)
    init.setup_templates!
    init.setup_secrets!
    init
  end

  # let(:dependency_root_path) do
  #   # "#{File.join(templates, root_deployment_name)}"
  #
  # end
  #
  # let(:enable_deployment_root_path) do
  #   "#{File.join(secrets, root_deployment_name)}/*"
  # end

  let(:deployment_factory) do
    DeploymentFactory.new(
     root_deployment_name,
     { 'stemcell-name'=> 'bosh-openstack-kvm-ubuntu-trusty-go_agent', 'stemcell-version' => 12 }
    )
  end

  after do
    FileUtils.rm_rf(secrets) unless secrets.nil?
    FileUtils.rm_rf(templates) unless templates.nil?
  end

  describe '#initialize' do
    it 'cannot initialize if a parameter is nil'
  end

  describe 'default_exclude' do
    expected_default_exclude = %w[secrets cf-apps-deployments terraform-config template].freeze

    context 'when default is used' do
      RootDeployment::DEFAULT_EXCLUDE.each do |excluded_dir|
        it "excludes #{excluded_dir} dir" do
          expect(expected_default_exclude).to include(excluded_dir)
        end
      end

      it 'excludes only expected dir' do
        expect(RootDeployment::DEFAULT_EXCLUDE.size).to eq(expected_default_exclude.size)
      end
    end
  end

  describe '#overview_from_hash' do

    let(:root_deployment) { described_class.new(root_deployment_name, templates, secrets) }

    before do
      dir_init
    end

    context 'when no enable-deployment.yml found and no secrets' do
      it 'returns an empty Hash' do
        expect(root_deployment.overview_from_hash(nil)).to be_empty
      end
    end

    context 'when no directory is excluded' do
      let(:root_deployment) { described_class.new(root_deployment_name, templates, secrets, []) }

      let(:overview) { root_deployment.overview_from_hash(deployment_factory) }

      xit 'returns directories in enable_deployment_root_path as inactive deployment' do
      end

      it 'contains an inactive secret deployment' do
        deployment = root_deployment.extract_deployment('secrets', overview)
        expect(deployment.disabled?).to be_truthy
      end

      it 'filters only excluded directory' do
        filtered_root_deployment = described_class.new(root_deployment_name, templates, secrets)
        filtered_overview = filtered_root_deployment.overview_from_hash(deployment_factory)
        filtered_overview_count = filtered_overview&.keys&.count
        overview_count = overview&.keys&.count

        expect(overview_count).to (be <= (filtered_overview_count + filtered_root_deployment.excluded_file&.count)).and \
          be >= filtered_overview_count

      end

    end
    context 'when no enable-deployment.yml found' do

      let(:overview) { root_deployment.overview_from_hash(deployment_factory) }

      before do
        init = dir_init
        init.add_deployment('ntp')
        init.add_deployment('credhub')
      end

      %w[ntp credhub].each { |deployment_name|
      it "returns #{deployment_name} deployment mark as disabled" do
        deployment = root_deployment.extract_deployment(deployment_name, overview)

        expect(deployment.disabled?).to be_truthy
      end
      }

      it 'ignores excluded directories' do
        expect(overview.keys).to match_array %w[credhub ntp]
      end

    end

    context 'when a enable-deployment.yml and a deployment-dependencies are found' do
      let(:overview) { root_deployment.overview_from_hash(deployment_factory) }

      before do
        init = dir_init
        init.add_deployment('ntp')
        init.enable_deployment('ntp')
        init.add_deployment('credhub')
        init.enable_deployment('credhub')
        init.add_deployment('mybosh')
      end

      %w[ntp credhub].each { |deployment_name|
        it "ensures #{deployment_name} deployment is enabled" do
          deployment = root_deployment.extract_deployment(deployment_name, overview)

          expect(deployment).to be_enabled
        end
      }

      it 'returns mybosh deployment mark as disabled' do
        deployment = root_deployment.extract_deployment('mybosh', overview)

        expect(deployment.disabled?).to be_truthy
      end

      it 'returns only directories to process' do
        expect(overview.keys).to match_array %w[credhub ntp mybosh]
      end

    end

    context 'when a enable-deployment.yml is found without a matching deployment-dependencies.yml' do
      let(:overview) { root_deployment.overview_from_hash(deployment_factory) }

      before do
        init = dir_init
        init.add_deployment('ntp')
        init.enable_deployment('ntp')
        filename = File.join(templates, root_deployment_name, 'ntp', 'deployment-dependencies.yml')
        File.delete(filename) if File.exist?(filename)

      end

      it 'raises an error' do
        expect { overview }.to raise_error(RuntimeError, "Inconsistency detected: deployment <ntp> is marked as active, but no deployment-dependencies.yml, nor other deployer config found at #{File.join(templates, root_deployment_name, 'ntp')}")
      end
    end
  end
end

