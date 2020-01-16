require 'rspec'
require 'yaml'
require 'fileutils'
require 'tmpdir'
require 'extended_config'

describe ExtendedConfig do
  subject(:extended_config) { ExtendedConfigBuilder.new.with_iaas_type(iaas_type).with_profiles(profiles).build }

  let(:iaas_type) { 'my_custom_iaas' }
  let(:profiles) { [] }
  let(:config_dir) { Dir.mktmpdir }

  describe '.new' do
    context 'when no customization provided' do
      subject(:extended_config) { ExtendedConfigBuilder.new.build }

      let(:expected_result) { described_class.new}

      it 'creates an empty object' do
        expect(extended_config).to eq(expected_result)
      end
    end
  end

  describe '.to_s' do
    subject(:extended_config) { ExtendedConfigBuilder.new.build }

    let(:expected_result) { "{}" }

    it 'creates an empty object' do
      expect(extended_config.to_s).to eq(expected_result)
    end
  end

  describe '.default_format' do
    context 'when no config provided' do
      let(:iaas_type) { nil }
      let(:expected_config) { { "default" => { "iaas" => "openstack", "profiles" => [] } } }

      it 'returns default values' do
        expect(extended_config.default_format).to eq(expected_config)
      end
    end

    context 'when only iaas is provided' do
      let(:expected_config) { { "default" => { "iaas" => 'my_custom_iaas', "profiles" => [] } } }

      it 'returns default values' do
        expect(extended_config.default_format).to eq(expected_config)
      end
    end

    context 'when only profiles is provided' do
      let(:profiles) { %w[p1 p2 p3] }
      let(:expected_config) { { "default" => { "iaas" => 'my_custom_iaas', "profiles" => %w[p1 p2 p3] } } }

      it 'returns default values' do
        expect(extended_config.default_format).to eq(expected_config)
      end
    end
  end
end
