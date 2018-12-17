require 'rspec'
require_relative '../../../lib/pipeline_helpers'

describe PipelineHelpers::PipelineConfigurer do
  let(:config) { {} }
  let(:root_deployment_name) { 'my_RD' }
  let(:pipeline_options) { PipelineHelpers::PipelineConfigurerOptions.new.with_config(config).with_root_deployment(root_deployment_name).build }
  let(:configurer) { described_class.new(pipeline_options) }

  context 'when a "default" configurer is created' do
    let(:expected_serial_group_strategy) { PipelineHelpers::SerialGroupRoundRobinNamingStrategy.name }

    it 'creates an object' do
      expect(configurer).not_to be_nil
    end

    it 'has a default serial_group_strategy' do
      expect(configurer.serial_group_strategy.class.name).to eq(expected_serial_group_strategy)
    end

    it 'has parallel_execution_limit disabled' do
      expect(configurer.parallel_execution_limit.get).to eq(-1)
    end
  end
end

describe PipelineHelpers::PipelineConfigurerOptions do

  context 'when missing parameters' do
    context 'when config is missing' do
      let(:builder) { described_class.new.with_config({}).build }

      it 'raise an error about missing root_deployment_name' do
        expect { builder }.to raise_error(PipelineHelpers::MissingPipelineConfigurerOptions, 'Missing root_deployment_name')
      end
    end

    context 'when config is missing' do
      let(:builder) { described_class.new.build }

      it 'raise an error about missing config' do
        expect { builder }.to raise_error(PipelineHelpers::MissingPipelineConfigurerOptions, 'Missing config')
      end
    end
  end

  context 'when all parameters are set' do
    let(:builder) { described_class.new.with_config({}).with_root_deployment('my_RD').build }

    it 'creates a valid object' do
      expect(builder).not_to be_nil
    end
  end
end
