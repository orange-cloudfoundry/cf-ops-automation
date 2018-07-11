require 'rspec'
require 'yaml'
require 'fileutils'
require 'tmpdir'
require 'config'

describe Config do
  let(:config_dir) { Dir.mktmpdir }
  let(:default_config) do
    {
      'offline-mode' => {
        'boshreleases' => false,
        'stemcells' => true,
        'docker-images' => false
      },
      'default' => {
        'stemcell' => {
          'name' => 'bosh-openstack-kvm-ubuntu-trusty-go_agent'
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
    subject { described_class.new('not-existing-public-config.yml', 'not-existing-private-config.yml') }

    it 'generates a default config when no yaml detected' do
      expect(subject.load_config.loaded_config).to eq(default_config)
    end

    context 'when shared config exists' do
      subject { described_class.new(shared_config_file, 'not-existing-private-config.yml') }

      let(:shared_config_file) { File.join(config_dir, 'my-public-config.yml') }
      let(:shared_config_file_content) { { 'public-override' => true, 'offline-mode' => false } }

      before do
        File.open(shared_config_file, 'w') do |file|
          file.write shared_config_file_content.to_yaml
        end
      end

      it 'overrides default value with shared-config' do
        expect(subject.load_config.loaded_config).to eq(default_config.merge(shared_config_file_content))
      end

      context 'when private config also exists' do
        subject { described_class.new(shared_config_file, private_config_file) }

        let(:private_config_file) { File.join(config_dir, 'my-private-config.yml') }
        let(:private_config_file_content) { { 'private-override' => true, 'offline-mode' => true } }

        before do
          File.open(private_config_file, 'w') do |file|
            file.write private_config_file_content.to_yaml
          end
        end

        it 'overrides value from shared-config with private-config' do
          expect(subject.load_config.loaded_config).
            to eq(default_config.merge(private_config_file_content.merge('public-override' => true)))
        end
      end
    end
  end

  describe '#stemcell_name' do
    subject { described_class.new(shared_config_file, 'not-existing-private-config.yml') }

    let(:shared_config_file) { File.join(config_dir, 'my-public-config.yml') }

    before do
      File.open(shared_config_file, 'w') { |file| file.write shared_config_file_content.to_yaml }
    end

    context 'when default is empty' do
      let(:shared_config_file_content) { { 'default' => {} } }

      it 'returns the default stemcell name' do
        subject.load_config
        expect(subject.stemcell_name).to eq(Config::DEFAULT_STEMCELL)
      end
    end

    context 'when stemcell does not contain name key' do
      let(:shared_config_file_content) { { 'default' => { 'stemcell' => "x" } } }

      it 'returns the default stemcell name' do
        subject.load_config
        expect(subject.stemcell_name).to eq(Config::DEFAULT_STEMCELL)
      end
    end

    context 'when stemcell is empty' do
      let(:shared_config_file_content) { { 'default' => { 'stemcell' => {} } } }

      it 'returns the default stemcell name' do
        subject.load_config
        expect(subject.stemcell_name).to eq(Config::DEFAULT_STEMCELL)
      end
    end

    context 'when stemcell is redefined' do
      let(:my_stemcell_name) { 'my_stemcell' }
      let(:shared_config_file_content) { { 'default' => { 'stemcell' => { 'name' => my_stemcell_name } } } }

      it 'returns the default stemcell name' do
        subject.load_config
        expect(subject.stemcell_name).to eq(my_stemcell_name)
      end
    end
  end
end
