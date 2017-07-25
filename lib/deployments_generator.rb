require 'yaml'
require 'tempfile'
require 'openssl'

class DeploymentsGenerator
  # attr_reader :root_deployment_name, :secrets_dir, :template_dir
  #
  # def initialize(root_deployment_name, secrets_dir, template_dir, terraform_dir = '')
  #   @root_deployment_name = root_deployment_name
  #   @secrets_dir = secrets_dir
  #   @template_dir = template_dir
  #   @terraform_dir = terraform_dir
  #   raise 'invalid root_deployment_name for directory initialiazer' unless validate_string @root_deployment_name
  #   raise 'invalid secrets_dir for directory initialiazer' unless validate_string @secrets_dir
  #   raise 'invalid template_dir for directory initialiazer' unless validate_string @template_dir
  # end


  def load_cert_from_location(base_dir, bosh_cert_hash)
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

  def generate_deployment_overview_from_hash(depls, paas_template_path, secrets_path, version_reference)
    dependencies = {}
    puts "Path deployment overview: #{secrets_path}"

    Dir[secrets_path].select { |f| File.directory? f }.each do |filename|
      dirname = filename.split('/').last
      puts "Processing #{dirname}"
      # Dir[filename + "/deployment-dependencies.yml"].each do |dependency_file|
      Dir[filename + '/enable-deployment.yml'].each do |_|
        dependency_file = "#{paas_template_path}/#{depls}/#{dirname}/deployment-dependencies.yml"

        puts "Bosh release detected: #{dirname}"
        current_dependecies = YAML.load_file(dependency_file)
        current_dependecies['deployment'].each do |deployment_name, deployment_details|

          raise "#{dependency_file} - Invalid deployment: expected <#{dirname}> - Found <#{deployment_name}>" if deployment_name != dirname
          dependencies[deployment_name] = deployment_details

          boshrelease_list = deployment_details['releases']
          boshrelease_list&.each do |a_release, _|
            #                puts "a_release: #{a_release}"
            version = version_reference[a_release + '-version']
            #                puts version
            deployment_details['releases'][a_release]['version'] = version
          end
          deployment_details['stemcells'].each do |a_stemcell, _|
            raise "#{dependency_file} - Invalid stemcell: expected <#{version_reference['stemcells-name']}> - Found <#{a_stemcell}>" if a_stemcell != version_reference['stemcell-name']

            version = version_reference['stemcell-version']
            # puts "####### #{version}"
            # deployment_details['stemcells'][a_stemcell]['version']= version
          end
        end
      end
      #puts "##############################"
      #    dependencies.each do |aDep|
      #        puts aDep
      #    end
      #puts "##############################"
    end
    puts "Dependencies loaded: \n#{YAML.dump(dependencies)}"
    dependencies
  end
end