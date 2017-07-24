require 'yaml'
require 'tempfile'
require 'erb'
require 'ostruct'
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

  def erb(template, vars)
    puts ERB.new(template).result(OpenStruct.new(vars).instance_eval { binding })
  end

  def generate_deployment_overview_from_hash(depls,paas_template_path, secrets_path, version_reference)
    dependencies= {}
    puts "Path deployment overview: #{secrets_path}"

    Dir[secrets_path].select { |f| File.directory? f }.each do |filename|
      dirname= filename.split('/').last
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
          boshrelease_list&.each do |aRelease, _|
            #                puts "arelease: #{aRelease}"
            version=version_reference[aRelease+'-version']
            #                puts version
            deployment_details['releases'][aRelease]['version']= version
          end
          deployment_details['stemcells'].each do |aStemcell, _|
            raise "#{dependency_file} - Invalid stemcell: expected <#{version_reference['stemcells-name']}> - Found <#{aStemcell}>" if aStemcell != version_reference['stemcell-name']

            version=version_reference['stemcell-version']
            # puts "####### #{version}"
            # deployment_details['stemcells'][aStemcell]['version']= version
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


# ci-deployment:
#     ops-depls:
#     target_name: concourse-ops
#     pipelines:
# ops-depls-generated:
#     config_file: concourse/pipelines/ops-depls-generated.yml
# vars_files:
#     - master-depls/concourse-ops/pipelines/credentials-ops-depls-pipeline.yml
# - ops-depls/ops-depls-versions.yml
# ops-depls-cf-apps-generated:
#     config_file: concourse/pipelines/ops-depls-cf-apps-generated.yml
# vars_files:
#     - master-depls/concourse-ops/pipelines/credentials-ops-depls-pipeline.yml
# - ops-depls/ops-depls-versions.yml
#

  def generate_ci_deployment_overview(path)
    ci_deployment= {}
    puts "Path CI deployment overview: #{path}"

    Dir[path].select { |f| File.directory? f }.each do |filename|
      dirname= filename.split('/').last
      puts "Processing #{dirname}"
      Dir[filename + '/ci-deployment-overview.yml'].each do |deployment_file|
        puts "CI deployment detected: #{dirname}"
        current_deployment=YAML.load_file(deployment_file)
        raise "#{deployment_file} - Invalid deployment: expected 'ci-deployment' key as yaml root" if (current_deployment == nil || current_deployment['ci-deployment'] == nil)
        current_deployment['ci-deployment'].each do |deployment_name, deployment_details|
          raise "#{deployment_file} - missing keys: expecting keys target and pipelines" if deployment_details == nil
          raise "#{deployment_file} - Invalid deployment: expected <#{dirname}> - Found <#{deployment_name}>" if deployment_name != dirname
          ci_deployment[deployment_name] = deployment_details

          raise "#{deployment_file} - No target defined: expecting a target_name" if deployment_details['target_name'] == nil

          raise "#{deployment_file} - No pipeline detected: expecting at least one pipeline" if deployment_details['pipelines'] == nil

          deployment_details['pipelines'].each do |pipeline_name, pipeline_details|
            raise "#{deployment_file} - missing keys: expecting keys vars_files and config_file (optional)" if pipeline_details == nil
            raise "#{deployment_file} - missing key: vars_files. Expecting an array of at least one concourse var file" if pipeline_details['vars_files'] == nil
            puts "Generating default value for key config_file in #{pipeline_name}" if pipeline_details['config_file'] == nil
            pipeline_details['config_file']= "concourse/pipelines/#{pipeline_name}.yml" if pipeline_details['config_file'] == nil
          end
        end
      end
      #puts "##############################"
      #    ci_deployment.each do |aDep|
      #        puts aDep
      #    end
      #puts "##############################"
    end
    puts "ci_deployment loaded: \n#{YAML.dump(ci_deployment)}"
    ci_deployment
  end


  def list_git_submodules(base_path)

    git_submodules = {}

    gitmodules = File.open("#{base_path}/.gitmodules") if File.exist? "#{base_path}/.gitmodules"
    gitmodules
        &.select { |line| line.strip!.start_with?('path =') }
        &.each { |path| path[0..6] = '' }
        &.each { |path|
      parsed_path=path.split('/')
      if parsed_path.length >2
        current_depls=parsed_path[0]
        current_deployment=parsed_path[1]
        item={current_deployment => [path]}
        # puts item
        unless git_submodules[current_depls]
          # puts "init #{current_depls}"
          git_submodules[current_depls]= {}
        end
        if ! git_submodules[current_depls][current_deployment]
          # puts "init #{current_depls} - #{current_deployment}"
          git_submodules[current_depls].merge! item
        else
          # puts "add #{current_depls} - #{current_deployment}: #{git_submodules[current_depls][current_deployment]} ## #{git_submodules}"
          # git_submodules.merge!(git_submodules[current_depls][current_deployment])
          git_submodules[current_depls][current_deployment] << path
        end
      end
    }
    gitmodules&.close
    git_submodules

  end

  def generate_cf_app_overview(path,depls_name)
    cf_apps= {}
    puts "Path CF App: #{path}"

    Dir[path].select { |f| File.directory? f }.each do |base_dir|
      dirname= base_dir.split('/').last
      puts "Processing CF App: #{dirname}"
      Dir.glob(base_dir + '/**/enable-cf-app.yml').each do |enable_cf_app_file|
        puts "Cf App detected: #{base_dir} - #{enable_cf_app_file}"
        enable_cf_app_file_dir=File.dirname(enable_cf_app_file)
        cf_app_desc=YAML.load_file(enable_cf_app_file)
        cf_app_desc['cf-app'].each do |cf_app_name, cf_app_details|
          puts "processing cf-app: #{cf_app_name} from #{enable_cf_app_file}"
          raise "cannot process #{enable_cf_app_file}, an application named #{cf_app_name} already exists" if cf_apps.has_key?(cf_app_name)
          #   raise "#{dependency_file} - Invalid deployment: expected <#{dirname}> - Found <#{deployment_name}>" if deployment_name != dirname
          cf_app_details['base-dir']= enable_cf_app_file_dir.sub(/^.*#{Regexp.escape(depls_name)}/, depls_name)

          cf_apps[cf_app_name] = cf_app_details
        end
      end
    end
    puts "cf_apps: \n#{YAML.dump(cf_apps)}"
    cf_apps
  end


  def generate_secrets_dir_overview(secrets_root)
    dir_overview={}

    Dir[secrets_root].select { |f| File.directory? f }.each do |depls_level_dir|
      depls_level_name= depls_level_dir.split('/').last
      puts "Processing depls level: #{depls_level_name}"
      dir_overview[depls_level_name]=[]
      Dir[depls_level_dir+'/*'].select { |f| File.directory? f }.each do |boshrelease_level_dir|
        boshrelease_level_name= boshrelease_level_dir.split('/').last
        puts "Processing boshrelease level: #{depls_level_name} -- #{boshrelease_level_name}"
        dir_overview[depls_level_name] << boshrelease_level_name
      end
    end
    dir_overview
  end


end