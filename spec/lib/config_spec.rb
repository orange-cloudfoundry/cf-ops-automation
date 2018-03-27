require 'rspec'
require 'yaml'
require 'fileutils'
require 'tmpdir'
require_relative '../../lib/config'

describe Config do
  let(:config_dir) { Dir.mktmpdir }
  let(:default_config) do
    {
      'offline-mode' => {
        'boshreleases' => false,
        'stemcells' => true,
        'docker-images' => false
      }
    }
  end

  # offline-mode:
  #   boshreleases: false
  #   stemcells: true
  #   docker-images: false

  describe 'shared-config.yml format validation' do
  end

  describe 'private-config.yml format validation' do
  end

  describe '#load' do
    subject { described_class.new('not-existing-public-config.yml', 'not-existing-private-config.yml') }

    it 'generates a default config when no yaml detected' do
      expect(subject.load).to eq(default_config)
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
        expect(subject.load).to eq(shared_config_file_content)
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
        expect(subject.load).to eq(private_config_file_content.merge({ 'public-override' => true}))
        end
      end
    end
  end
end
