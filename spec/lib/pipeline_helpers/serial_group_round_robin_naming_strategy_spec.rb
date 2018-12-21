require 'rspec'
require_relative '../../../lib/pipeline_helpers'

describe PipelineHelpers::SerialGroupRoundRobinNamingStrategy do
  let(:max_pool_size) { 7 }

  describe '#generate' do
    let(:dummy_prefix) { 'dummy-prefix-' }
    let(:strategy) { described_class.new(max_pool_size, dummy_prefix) }
    let(:deployment_name) { 'a_deployment_name' }
    let(:empty_details) { {} }

    context 'when a single generation is required' do
      let(:generated_pool_name) { strategy.generate(deployment_name, empty_details) }

      it 'generates a pool name suffix' do
        expected_suffix = '-0'
        expect(generated_pool_name).to end_with(expected_suffix)
      end

      it 'generates a pool name with custom prefix' do
        expect(generated_pool_name).to start_with(dummy_prefix)
      end
    end

    context 'when a multiple generation is required' do
      let(:generated_pool_names) do
        result = []
        max_pool_size.times { result << strategy.generate(deployment_name, empty_details) }
        result
      end
      let(:expected_pool_names) { (0..max_pool_size - 1).flat_map { |i| dummy_prefix.to_s + (i.to_s % max_pool_size) } }

      it 'generates always the same name' do
        expect(generated_pool_names).to match expected_pool_names
      end
    end
  end
end