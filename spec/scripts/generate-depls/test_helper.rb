require 'openssl'
require 'fileutils'
require 'yaml'

RSpec.shared_examples 'pipeline checker' do |generated_pipeline_name, reference_pipeline|
  test_path = File.dirname(__FILE__)

  it "(compares #{generated_pipeline_name} with #{reference_pipeline})" do
    reference_file = YAML.load_file("#{test_path}/fixtures/references/#{reference_pipeline}", aliases: true) || {}
    expected_generated_dir = File.join(output_path, 'pipelines')
    expected_generated_filename = File.join(expected_generated_dir, generated_pipeline_name)
    raise "file not found: #{expected_generated_filename}. Dir content: #{Dir.glob(expected_generated_dir + '/*')}" unless File.exist?(expected_generated_filename)
    generated_file = YAML.load_file(expected_generated_filename, aliases: true)
    expect(generated_file.to_yaml).to eq(reference_file.to_yaml)
  end
end

class TestHelper
  def self.load_generated_pipeline(output_path, generated_pipeline_name)
    expected_generated_dir = File.join(output_path, 'pipelines')
    expected_generated_filename = File.join(expected_generated_dir, generated_pipeline_name)
    raise "file not found: #{expected_generated_filename}. Dir content: #{Dir[expected_generated_dir].to_s}" unless File.exist?(expected_generated_filename)
    YAML.load_file(expected_generated_filename, aliases: true)
  end

  def self.generate_deployment_bosh_ca_cert(secrets_path)
    crt_path = "#{secrets_path}/shared/certs/internal_paas-ca/server-ca.crt"
    File.delete(crt_path) if File.exist? crt_path
    crt_content = File.read(File.dirname(__FILE__) + "/fixtures/server-ca.crt")
    dir = File.dirname(crt_path)
    FileUtils.mkdir_p dir unless Dir.exist? dir
    file = File.new(crt_path, 'w')
    file << crt_content
    file.close
  end
end
