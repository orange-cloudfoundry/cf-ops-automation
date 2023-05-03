shared_examples 'a ConfigGetter' do |expected_key, intermediate_key = Config::CONFIG_CONCOURSE_KEY|
  let(:root_deployment_name) { 'root_deployment_sample_name' }
  let(:config_getter_subclass) { described_class.new(config, root_deployment_name) }

  def config_builder(root_deployment_name, middle_key, final)
    if middle_key.to_s.empty?
      { root_deployment_name => final }
    else
      { root_deployment_name => { middle_key => final }}
    end
  end

  describe '.extract' do
    let(:extracted_value) { config_getter_subclass.extract(root_deployment_name) }

    context 'when config contains expected key' do
      let(:config) { config_builder(root_deployment_name, intermediate_key, {expected_key => expected_grabbed_value} ) }
      let(:expected_grabbed_value) { 7 }

      it 'returns value found' do
        expect(extracted_value).to eq(expected_grabbed_value)
      end
    end

    context "when #{expected_key} key is missing" do
      let(:config) { config_builder(root_deployment_name, intermediate_key,{ 'xxx' => 5 }) }

      it 'returns nil' do
        expect(extracted_value).to be_nil
      end
    end

    context 'when concourse_key is missing' do
      let(:config) { { root_deployment_name => { 'xxx' => 5 } } }

      it 'returns nil' do
        expect(extracted_value).to be_nil
      end
    end

    context 'when config is empty' do
      let(:config) { {} }

      it 'returns nil' do
        expect(extracted_value).to be_nil
      end
    end
  end

  describe '.get and .overridden?' do
    let(:expected_root_deployment_overriden_value) { 'my_rdo_value' }
    let(:expected_default_overriden_value) { 'my_default_value' }
    let(:expected_undefined_value) { config_getter_subclass.default_value }
    let(:root_deployment_config_override) { config_builder( root_deployment_name, intermediate_key, { expected_key => expected_root_deployment_overriden_value }) }
    let(:default_config_override) { config_builder(Config::CONFIG_DEFAULT_KEY, intermediate_key, { expected_key => expected_default_overriden_value }) }
    let(:retrieved_value) { config_getter_subclass.get }
    let(:is_overriden) { config_getter_subclass.overridden? }

    context 'when value is overridden by root_deployment' do
      let(:config) { root_deployment_config_override.merge default_config_override }

      it 'returns config value defined by root_deployment' do
        expect(retrieved_value).to eq expected_root_deployment_overriden_value
      end

      it 'detects an overridden value' do
        expect(is_overriden).to be true
      end
    end

    context 'when default value is overridden' do
      let(:config) { default_config_override }

      it 'returns config value defined by default' do
        expect(retrieved_value).to eq expected_default_overriden_value
      end

      it 'detects an overridden value' do
        expect(is_overriden).to be true
      end
    end

    context 'when default value is used' do
      let(:config) { {} }

      it 'returns raw default value' do
        expect(retrieved_value).to eq expected_undefined_value
      end

      it 'detects an overridden value' do
        expect(is_overriden).to be false
      end
    end
  end
end
