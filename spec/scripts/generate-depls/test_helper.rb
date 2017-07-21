

RSpec.shared_examples 'pipeline checker' do |generated_pipeline_name, reference_pipeline|
  test_path = File.dirname(__FILE__)

  it "(compares #{generated_pipeline_name} with #{reference_pipeline})" do
    __FILE__
    reference_file = YAML.load_file("#{test_path}/fixtures/references/#{reference_pipeline}") || {}
    generated_file = YAML.load_file "#{output_path}/pipelines/#{generated_pipeline_name}"
    expect(generated_file).to eq(reference_file)
  end
end
