require 'tempfile'
require 'openssl'

class BoshCertificates


  def load_from_location(base_dir, bosh_cert_hash)
    certs = {}
    bosh_cert_hash.each do |depls_name, cert_path|
      next unless File.exist? "#{base_dir}/#{cert_path}"

      ca_cert = OpenSSL::X509::Certificate.new(File.read("#{base_dir}/#{cert_path}"))
      certs[depls_name] = ca_cert.to_pem
    end
    unless bosh_cert_hash.default.nil?
      if File.exist?("#{base_dir}/#{bosh_cert_hash.default}")
        ca_cert = OpenSSL::X509::Certificate.new(File.read("#{base_dir}/#{bosh_cert_hash.default}"))
        certs.default = ca_cert.to_pem
      end
    end
    certs
  end

end