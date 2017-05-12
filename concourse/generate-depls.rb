#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'
require 'optparse'
require 'tempfile'
require 'erb'
require 'ostruct'

# TODO add rspec file to avoid regression
BOSH_CERT_LOCATIONS={
    "micro-depls" => "inception/micro-bosh/secrets/certificates/certs/rootCA.pem",
    "master-depls" => "micro-depls/bosh-master/secrets/certificates/certs/rootCA.pem",
    "expe-depls" => "master-depls/bosh-expe/secrets/certificates/certs/rootCA.pem",
    "ops-depls" => "master-depls/bosh-ops/secrets/certificates/certs/rootCA.pem"
}
# Argument parsing
OPTIONS = {
  :common_version_path => "..",
  :submodule_path => ".." ,
  :deployment_dependencies_path=> ".."
}
opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: ./#{opts.program_name} <options>"

  opts.on("-d", "--depls DEPLOYMENT", "Specify a deployment name to generate template for. MANDATORY") do |deployment_string|
    OPTIONS[:depls]= deployment_string
  end

  opts.on("-c", "--common-version-path PATH", "Base location for <depls>/<depls>-versions.yml") do |cvp_string|
    OPTIONS[:common_version_path]= cvp_string
  end

  opts.on("-s", "--submodule-path PATH", ".gitsubmodule path") do |sp_string|
    OPTIONS[:submodule_path]= sp_string
  end

  opts.on("-p", "--deployment-dependencies-path PATH", "Base scan dir for deployment-dependencies.yml") do |ddp_string|
    OPTIONS[:deployment_dependencies_path]= ddp_string
  end

end
opt_parser.parse!

depls = OPTIONS[:depls]
opt_parser.abort("#{opt_parser}") if depls == nil

def erb(template, vars)
  puts ERB.new(template).result(OpenStruct.new(vars).instance_eval { binding })
end

def header(msg)
  print '*' * 10
  puts " #{msg}"
end

def generate_deployment_overview_from_array(path, version_reference)
  all_dependencies= []
  Dir[path].select { |f| File.directory? f }.each do |filename|
    dirname= filename.split('/').last
    puts "Processing #{dirname}"
    Dir[filename + "/deployment-dependencies.yml"].each do |dependency_file|
      puts "Bosh release detected: #{dirname}"
      current_dependecies=YAML.load_file(dependency_file)
      current_dependecies["deployment"].each do |aDep|
        raise "#{dependency_file} - Invalid deployment: expected <#{dirname}> - Found <#{aDep["name"]}>" if aDep["name"] != dirname
#            puts aDep["name"]
#            puts aDep["releases"]
        all_dependencies << aDep

        aDep["releases"].each do |aRelease|
#                puts "arelease: #{aRelease}"
          version=version_reference[aRelease['name']+'-version']
          aRelease['version']= version
        end
        raise "" #{dependency_file} - Invalid stemcell: expected <#{version_reference['stemcell-name'}> - Found <#{aDep["stemcells"][0]["name"]}>" if aDep["stemcells"][0]["name"] != version_reference['stemcell-name']
        version=version_reference['stemcell-version']
        aDep["stemcells"][0]['version']= version
      end
    end
    #puts "##############################"
    #    all_dependencies.each do |aDep|
    #        puts aDep
    #    end
    #puts "##############################"
    puts YAML.dump(all_dependencies)
  end
end

def generate_deployment_overview_from_hash(path, version_reference)
  dependencies= {}

  Dir[path].select { |f| File.directory? f }.each do |filename|
    dirname= filename.split('/').last
    puts "Processing #{dirname}"
    Dir[filename + "/deployment-dependencies.yml"].each do |dependency_file|
      puts "Bosh release detected: #{dirname}"
      current_dependecies=YAML.load_file(dependency_file)
      current_dependecies["deployment"].each do |deployment_name, deployment_details|

        raise "#{dependency_file} - Invalid deployment: expected <#{dirname}> - Found <#{deployment_name}>" if deployment_name != dirname
        dependencies[deployment_name] = deployment_details

        deployment_details['releases'].each do |aRelease, _|
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
    Dir[filename + "/ci-deployment-overview.yml"].each do |deployment_file|
      puts "CI deployment detected: #{dirname}"
      current_deployment=YAML.load_file(deployment_file)
      raise "#{deployment_file} - Invalid deployment: expected 'ci-deployment' key as yaml root" if (current_deployment == nil || current_deployment["ci-deployment"] == nil)
      current_deployment["ci-deployment"].each do |deployment_name, deployment_details|
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
  git_submodules= {}

  gitmodules=File.open("#{base_path}/.gitmodules")
  gitmodules.select{|line| line.strip!.start_with?("path =")}
      .each { |path| path[0..6]=""}
      .each { |path|
      parsed_path=path.split("/")
      if parsed_path.length >2
        current_depls=parsed_path[0]
        current_deployment=parsed_path[1]
        item={current_deployment => [path]}
        # puts item
        if ! git_submodules[current_depls]
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
  gitmodules.close
  git_submodules

end

def generate_cf_app_overview(path,depls_name)
  cf_apps= {}
  puts "Path CF App: #{path}"

  Dir[path].select { |f| File.directory? f }.each do |base_dir|
    dirname= base_dir.split('/').last
    puts "Processing CF App: #{dirname}"
    Dir.glob(base_dir + "/**/enable-cf-app.yml").each do |enable_cf_app_file|
      puts "Cf App detected: #{base_dir} - #{enable_cf_app_file}"
      enable_cf_app_file_dir=File.dirname(enable_cf_app_file)
      cf_app_desc=YAML.load_file(enable_cf_app_file)
      cf_app_desc["cf-app"].each do |cf_app_name, cf_app_details|
        puts "processing cf-app: #{cf_app_name} from #{enable_cf_app_file}"
        raise "cannot process #{enable_cf_app_file}, an application named #{cf_app_name} already exists" if cf_apps.has_key?(cf_app_name)
        #   raise "#{dependency_file} - Invalid deployment: expected <#{dirname}> - Found <#{deployment_name}>" if deployment_name != dirname
        cf_app_details["base-dir"]= enable_cf_app_file_dir.sub(/^.*#{Regexp.escape(depls_name)}/, depls_name)

        cf_apps[cf_app_name] = cf_app_details
      end
    end
  end
  puts "cf_apps: \n#{YAML.dump(cf_apps)}"
  cf_apps
end




version_reference = YAML.load_file("#{OPTIONS[:common_version_path]}/#{depls}/#{depls}-versions.yml")
all_dependencies=generate_deployment_overview_from_hash("#{OPTIONS[:deployment_dependencies_path]}/" + depls + '/*', version_reference)

raise "all_dependencies should not be empty" if all_dependencies.empty?
all_ci_deployments=generate_ci_deployment_overview("#{OPTIONS[:deployment_dependencies_path]}/" + depls)

all_cf_apps=generate_cf_app_overview("#{OPTIONS[:deployment_dependencies_path]}/#{depls}/*",depls)


git_submodules=list_git_submodules(OPTIONS[:submodule_path])

Dir['pipelines/template/depls-pipeline.yml', 'pipelines/template/cf-apps-pipeline.yml', 'pipelines/template/news-pipeline.yml','pipelines/template/sync-helper-pipeline.yml'].each do |filename|
  puts "processing #{filename}"
  puts output=ERB.new(File.read(filename)).result()

  # trick to avoid pipeline name like ops-depls-depls-generated or ops-depls--generated
  tmp_pipeline_name= filename.split("/").last().chomp("-pipeline.yml").chomp("depls")
  pipeline_name= "#{depls}-"
  pipeline_name << "#{tmp_pipeline_name}-" if ! tmp_pipeline_name.nil? && ! tmp_pipeline_name.empty?
  pipeline_name << "generated.yml"

  puts "Pipeline name #{pipeline_name}"
  aPipeline=File.new("pipelines/#{pipeline_name}", "w")
  aPipeline << output
  puts "Trying to parse generated Yaml: #{pipeline_name}"
  YAML.load_file(aPipeline)
  puts "> #{pipeline_name} seems a valid Yaml file"
  puts "####################################################################################"
  puts "####################################################################################"

end

puts "### WARNING ### no ci deployment detected. Please check a valid ci-deployment-overview.yml exists" if all_ci_deployments.empty?
puts "### WARNING ### no cf app deployment detected. Please check a valid enable-cf-app.yml exists" if all_cf_apps.empty?
puts "### WARNING ### no gitsubmodule detected" if git_submodules.empty?
puts
puts 'Thanks, Orange CloudFoundry SKC'
