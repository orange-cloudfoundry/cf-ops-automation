require 'openssl'

# Create or load SSL certificates to be able to connect to a Bosh Director
class BoshCertificates
  attr_reader :base_dir, :bosh_cert_hash, :certs

  def initialize(base_dir, bosh_cert_hash)
    @base_dir = base_dir
    @bosh_cert_hash = bosh_cert_hash
    @certs = {}
  end

  def load_from_location
    load_deployments_certs
    load_default_cert if bosh_cert_hash.default && File.exist?("#{base_dir}/#{bosh_cert_hash.default}")
    self
  end

  private

  def load_deployments_certs
    bosh_cert_hash.each do |depls_name, cert_path|
      next unless File.exist? "#{base_dir}/#{cert_path}"

      ca_cert = OpenSSL::X509::Certificate.new(File.read("#{base_dir}/#{cert_path}"))
      certs[depls_name] = ca_cert.to_pem
    end

    certs
  end

  def load_default_cert
    ca_cert = OpenSSL::X509::Certificate.new(File.read("#{base_dir}/#{bosh_cert_hash.default}"))
    certs.default = ca_cert.to_pem
  end
end
