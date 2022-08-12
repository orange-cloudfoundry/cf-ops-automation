require 'rspec'
require 'yaml'
require 'fileutils'
require 'tmpdir'
require 'config'

describe Config do
  let(:config_dir) { Dir.mktmpdir }
  let(:extended_config) { ExtendedConfigBuilder.new.with_iaas_type('my_custom_iaas').build }
  let(:default_config) do
    {
      'offline-mode' => {
        'boshreleases' => false,
        'stemcells' => true,
        'docker-images' => false
      },
      'default' => {
        'bosh-options' => { 'cleanup' => true, 'dry_run' => false, 'fix' => false, 'max_in_flight' => nil, 'no_redact' => false, 'recreate' => false, 'skip_drain' => [] },
        'iaas' => 'my_custom_iaas',
        'profiles' => [],
        'stemcell' => {
          'name' => 'bosh-openstack-kvm-ubuntu-bionic-go_agent'
        },
        'retry' => {
          'task' => 2,
          'bosh-push' => 2,
          'pull' => 2,
          'push' => 2
        },
        'concourse' => {
          'parallel_execution_limit' => 5
        }
      }
    }
  end

  # offline-mode:
  #   boshreleases: false
  #   stemcells: true
  #   docker-images: false

  describe 'shared-config.yml format validation'
  describe 'private-config.yml format validation'

  describe '#load_config' do
    subject(:config) { described_class.new('not-existing-public-config.yml', 'not-existing-private-config.yml', extended_config) }

    it 'generates a default config when no yaml detected' do
      expect(config.load_config.loaded_config).to eq(default_config)
    end

    context 'when shared, private and extended config has same key' do
      subject(:config) { described_class.new('my-public-config.yml', 'private-config.yml', extended_config) }

      let(:shared_config_result) { { 'default' => { 'iaas' => 'shared', 'profiles' => %w[shared-profile], 'bosh-options' => { 'fix' => true } }, shared: true } }
      let(:private_config_result) { { 'default' => { 'iaas' => 'private', 'profiles' => %w[private-profile], 'bosh-options' => { 'max_in_flight' => 10 } }, private: true } }
      let(:extended_config_result) { { 'default' => { 'iaas' => 'extended', 'profiles' => %w[x-profile], 'retry' => { 'bosh-push' => 1 } } } }
      let(:extended_config) { instance_double(ExtendedConfig) }
      let(:expected_loaded_config) do
        { 'default' =>
          {
            'bosh-options' => { 'cleanup' => true, 'dry_run' => false, 'fix' => true, 'max_in_flight' => 10, 'no_redact' => false, 'recreate' => false, 'skip_drain' => [] },
            'concourse' => {'parallel_execution_limit' => 5 },
            'iaas' => 'extended', 'profiles' => ['x-profile'], 'stemcell' => { 'name' => 'bosh-openstack-kvm-ubuntu-bionic-go_agent' },
            'retry'=> { 'task' => 2, 'bosh-push'=> 1, 'pull'=> 2, 'push'=> 2 }
          },
          'offline-mode' => { 'boshreleases' => false, 'docker-images' => false, 'stemcells' => true },
          :private => true, :shared => true }
      end

      before do
        allow(File).to receive(:exist?).with('my-public-config.yml').and_return(true)
        allow(YAML).to receive(:load_file).with('my-public-config.yml',any_args).and_return(shared_config_result)
        allow(File).to receive(:exist?).with('private-config.yml').and_return(true)
        allow(YAML).to receive(:load_file).with('private-config.yml',any_args).and_return(private_config_result)
        allow(extended_config).to receive(:default_format).and_return(extended_config_result)
      end

      it 'uses value from extended config' do
        expect(config.load_config.loaded_config).to eq(expected_loaded_config)
      end
    end

    context 'when shared config exists' do
      subject(:config) { described_class.new(shared_config_file, 'not-existing-private-config.yml', extended_config) }

      let(:shared_config_file) { File.join(config_dir, 'my-public-config.yml') }
      let(:shared_config_file_content) { { 'public-override' => true, 'offline-mode' => false } }

      before do
        File.open(shared_config_file, 'w') do |file|
          file.write shared_config_file_content.to_yaml
        end
      end

      it 'overrides default value with shared-config' do
        expect(config.load_config.loaded_config).to eq(default_config.merge(shared_config_file_content))
      end

      context 'when private config also exists' do
        subject(:config) { described_class.new(shared_config_file, private_config_file, extended_config) }

        let(:private_config_file) { File.join(config_dir, 'my-private-config.yml') }
        let(:private_config_file_content) { { 'private-override' => true, 'offline-mode' => true } }

        before do
          File.open(private_config_file, 'w') do |file|
            file.write private_config_file_content.to_yaml
          end
        end

        it 'overrides value from shared-config with private-config' do
          expect(config.load_config.loaded_config).
            to eq(default_config.merge(private_config_file_content.merge('public-override' => true)))
        end
      end
    end
  end

  describe '#stemcell_name' do
    subject(:config) { described_class.new(shared_config_file, 'not-existing-private-config.yml') }

    let(:shared_config_file) { File.join(config_dir, 'my-public-config.yml') }

    before do
      File.open(shared_config_file, 'w') { |file| file.write shared_config_file_content.to_yaml }
      config.load_config
    end

    context 'when default is empty' do
      let(:shared_config_file_content) { { 'default' => {} } }

      it 'returns the default stemcell name' do
        expect(config.stemcell_name).to eq(Config::DEFAULT_STEMCELL)
      end
    end

    context 'when stemcell does not contain name key' do
      let(:shared_config_file_content) { { 'default' => { 'stemcell' => 'x' } } }

      it 'returns the default stemcell name' do
        expect(config.stemcell_name).to eq(Config::DEFAULT_STEMCELL)
      end
    end

    context 'when stemcell is nil' do
      let(:shared_config_file_content) { { 'default' => { 'stemcell' => nil } } }

      it 'returns the default stemcell name' do
        expect(config.stemcell_name).to eq(Config::DEFAULT_STEMCELL)
      end
    end

    context 'when stemcell is empty' do
      let(:shared_config_file_content) { { 'default' => { 'stemcell' => {} } } }

      it 'returns the default stemcell name' do
        expect(config.stemcell_name).to eq(Config::DEFAULT_STEMCELL)
      end
    end

    context 'when stemcell is redefined in default' do
      let(:my_stemcell_name) { 'my_stemcell' }
      let(:shared_config_file_content) { { 'default' => { 'stemcell' => { 'name' => my_stemcell_name } } } }

      it 'returns the default stemcell name' do
        expect(config.stemcell_name).to eq(my_stemcell_name)
      end
    end

    context 'when stemcell is redefined in root_deployment' do
      let(:my_root_deployment_name) { 'my_root_deployment' }
      let(:my_stemcell_name) { 'my_stemcell' }
      let(:shared_config_file_content) do
        {
          'default' => { 'stemcell' => { 'name' => 'default_stemcell' } },
          my_root_deployment_name => { 'stemcell' => { 'name' => my_stemcell_name } }
        }
      end

      it 'returns overridden stemcell name' do
        expect(config.stemcell_name(my_root_deployment_name)).to eq(my_stemcell_name)
      end
    end
  end

  describe '.iaas' do
    subject(:config) { described_class.new('my-public-config.yml', 'private-config.yml', extended_config) }

    let(:extended_config) { instance_double(ExtendedConfig) }

    before do
      allow(extended_config).to receive(:default_format).and_return(extended_config_result)
    end

    context "when iaas_type is defined" do
      let(:expected_iaas_type) { 'my_custom_iaas' }
      let(:extended_config_result) { { "default" => { "iaas" => 'my_custom_iaas' } } }

      it "returns a valid iaas_type" do
        expect(config.iaas_type).to match(expected_iaas_type)
      end
    end

    context "when no iaas_type defined" do
      let(:extended_config_result) { { "default" => {} } }
      let(:expected_iaas_type) { '' }

      it "returns empty iaas_type" do
        expect(config.iaas_type).to match(expected_iaas_type)
      end
    end
  end

  describe '.profiles' do
    subject(:config) { described_class.new('my-public-config.yml', 'private-config.yml', extended_config) }

    let(:extended_config) { instance_double(ExtendedConfig) }

    before do
      allow(extended_config).to receive(:default_format).and_return(extended_config_result)
    end

    context "when no profiles defined" do
      let(:extended_config_result) { { "default" => {} } }
      let(:expected_profiles) { [] }

      it "returns an empty profile list" do
        expect(config.profiles).to match(expected_profiles)
      end
    end

    context "when profiles are defined" do
      let(:profiles) { %w[profile-1 profile-2] }
      let(:extended_config_result) { { "default" => { "profiles" => profiles } } }
      let(:expected_profiles) { %w[profile-1 profile-2] }

      it "returns profiles loaded" do
        expect(config.profiles).to match(expected_profiles)
      end
    end

    context "when profiles is overridden" do
      subject(:config) { described_class.new(shared_config_file, 'not-existing-private-config.yml', extended_config) }

      let(:extended_config_result) { { "default" => { "profiles" => %w[extended-profile] } } }
      let(:root_deployment_name) { 'my_root' }
      let(:shared_config_file) { File.join(config_dir, 'my-public-config.yml') }

      before do
        File.open(shared_config_file, 'w') { |file| file.write shared_config_file_content.to_yaml }
        config.load_config
      end

      context "when only default is provided" do
        let(:shared_config_file_content) { { 'default' => { "profiles" => %w[shared-profile] } } }
        let(:extended_config_result) { { "default" => { "profiles" => [] } } }
        let(:expected_profiles) { %w[] }

        it "returns extended profiles default value " do
          expect(config.profiles(root_deployment_name)).to match(expected_profiles)
        end
      end

      context "when default and extended profiles are provided" do
        let(:shared_config_file_content) { { 'default' => { "profiles" => %w[shared-profile] } } }
        let(:expected_profiles) { %w[extended-profile] }

        it "always returns extended profiles value" do
          expect(config.profiles(root_deployment_name)).to match(expected_profiles)
        end
      end

      context "when root_deployment, default and extended profiles are provided" do
        let(:shared_config_file_content) { { 'default' => { "profiles" => %w[shared-profile] }, root_deployment_name => { "profiles" => %w[my-profile] } } }
        let(:expected_profiles) { %w[my-profile] }

        it "returns root profiles value" do
          expect(config.profiles(root_deployment_name)).to match(expected_profiles)
        end
      end
    end
  end

  describe '.bosh_options' do
    subject(:config) { described_class.new(shared_config_file, 'not-existing-private-config.yml') }

    let(:root_deployment_name) { 'my_root' }
    let(:shared_config_file) { File.join(config_dir, 'my-public-config.yml') }
    let(:expected_bosh_options) { { 'cleanup' => true, 'no_redact' => false, 'dry_run' => false, 'fix' => false, 'recreate' => false, 'max_in_flight' => nil, 'skip_drain' => [] } }

    before do
      File.open(shared_config_file, 'w') { |file| file.write shared_config_file_content.to_yaml }
      config.load_config
    end

    context 'when default is empty' do
      let(:shared_config_file_content) { { 'default' => {} } }

      it 'returns the default bosh options' do
        expect(config.bosh_options(root_deployment_name)).to eq(expected_bosh_options)
      end
    end

    context 'when bosh options does not contain expected key' do
      let(:shared_config_file_content) { { 'default' => { 'stemcell' => 'x' } } }

      it 'returns the default bosh options' do
        expect(config.bosh_options(root_deployment_name)).to eq(expected_bosh_options)
      end
    end

    context 'when bosh_options is nil' do
      let(:shared_config_file_content) { { 'default' => { 'bosh-options' => nil } } }

      it 'returns empty options' do
        expect(config.bosh_options(root_deployment_name)).to be_empty
      end
    end

    context 'when bosh options is empty' do
      let(:shared_config_file_content) { { 'default' => { 'bosh-options' => {} } } }

      it 'returns the default stemcell name' do
        expect(config.bosh_options(root_deployment_name)).to eq(expected_bosh_options)
      end
    end

    context 'when bosh options are overridden by default' do
      let(:shared_config_file_content) do
        { 'default' => { 'stemcell' => 'x', 'bosh-options' => { 'fix' => true, 'no_redact' => true, 'max_in_flight' => 5 } } }
      end
      let(:expected_bosh_options) { { 'cleanup' => true, 'no_redact' => true, 'dry_run' => false, 'fix' => true, 'recreate' => false, 'max_in_flight' => 5, 'skip_drain' => [] } }

      it 'returns the default bosh options' do
        expect(config.bosh_options(root_deployment_name)).to eq(expected_bosh_options)
      end
    end

    context 'when bosh options are overridden by root_deployment' do
      let(:shared_config_file_content) do
        { 'default' => { 'stemcell' => 'x', 'bosh-options' => { 'fix' => true, 'no_redact' => true, 'max_in_flight' => 5 } },
          root_deployment_name => { 'bosh-options' => { 'cleanup' => false, 'max_in_flight' => 10 } } }
      end
      let(:expected_bosh_options) { { 'cleanup' => false, 'no_redact' => true, 'dry_run' => false, 'fix' => true, 'recreate' => false, 'max_in_flight' => 10, 'skip_drain' => [] } }

      it 'returns the default bosh options' do
        expect(config.bosh_options(root_deployment_name)).to eq(expected_bosh_options)
      end
    end

    context 'when bosh options are overridden by nil root_deployment' do
      let(:shared_config_file_content) do
        { 'default' => { 'stemcell' => 'x', 'bosh-options' => { 'fix' => true, 'no_redact' => true, 'max_in_flight' => 5 } },
          root_deployment_name => { 'bosh-options' => nil } }
      end
      let(:expected_bosh_options) { { 'cleanup' => true, 'no_redact' => true, 'dry_run' => false, 'fix' => true, 'recreate' => false, 'max_in_flight' => 5, 'skip_drain' => [] } }

      it 'returns the default bosh options' do
        expect(config.bosh_options(root_deployment_name)).to eq(expected_bosh_options)
      end
    end
  end
end
