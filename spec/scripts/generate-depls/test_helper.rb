

RSpec.shared_examples 'pipeline checker' do |generated_pipeline_name, reference_pipeline|
  test_path = File.dirname(__FILE__)

  it "(compares #{generated_pipeline_name} with #{reference_pipeline})" do
    __FILE__
    reference_file = YAML.load_file("#{test_path}/fixtures/references/#{reference_pipeline}") || {}
    generated_file = YAML.load_file "#{output_path}/pipelines/#{generated_pipeline_name}"
    expect(generated_file).to eq(reference_file)
  end
end

require 'openssl'
require 'fileutils'
class TestHelper
  def self.create_test_root_ca(root_ca_filename)
    root_key = OpenSSL::PKey::RSA.new 2048 # the CA's public/private key
    root_ca = OpenSSL::X509::Certificate.new
    root_ca.version = 2 # cf. RFC 5280 - to make it a "v3" certificate
    root_ca.serial = 1
    root_ca.subject = OpenSSL::X509::Name.parse '/DC=com/DC=orange/CN=Test CA'
    root_ca.issuer = root_ca.subject # root CA's are "self-signed"
    root_ca.public_key = root_key.public_key
    root_ca.not_before = Time.now
    root_ca.not_after = root_ca.not_before + 2 * 365 * 24 * 60 * 60 # 2 years validity
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = root_ca
    ef.issuer_certificate = root_ca
    root_ca.add_extension(ef.create_extension('basicConstraints', 'CA:TRUE', true))
    root_ca.add_extension(ef.create_extension('keyUsage', 'keyCertSign, cRLSign', true))
    root_ca.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
    root_ca.add_extension(ef.create_extension('authorityKeyIdentifier', 'keyid:always', false))
    root_ca.sign(root_key, OpenSSL::Digest::SHA256.new)

    dir=File.dirname(root_ca_filename)
    FileUtils.mkdir_p dir unless Dir.exist? dir
    file = File.new(root_ca_filename, 'w')
    file << root_ca.to_pem
    file.close
  end
end
