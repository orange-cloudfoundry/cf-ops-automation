#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'
require 'optparse'
require 'tempfile'
require 'erb'
require 'ostruct'

# TODO add rspec file to avoid regression

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
  all_dependencies= {}

  Dir[path].select { |f| File.directory? f }.each do |filename|
    dirname= filename.split('/').last
    puts "Processing #{dirname}"
    Dir[filename + "/deployment-dependencies.yml"].each do |dependency_file|
      puts "Bosh release detected: #{dirname}"
      current_dependecies=YAML.load_file(dependency_file)
      current_dependecies["deployment"].each do |deployment_name, deployment_details|

        raise "#{dependency_file} - Invalid deployment: expected <#{dirname}> - Found <#{deployment_name}>" if deployment_name != dirname
        all_dependencies[deployment_name] = deployment_details

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
    #    all_dependencies.each do |aDep|
    #        puts aDep
    #    end
    #puts "##############################"
  end
  puts "all_dependencies loaded: \n#{YAML.dump(all_dependencies)}"
  all_dependencies
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

all_cf_apps=generate_cf_app_overview("#{OPTIONS[:deployment_dependencies_path]}/#{depls}/*",depls)


git_submodules=list_git_submodules(OPTIONS[:submodule_path])

Dir['pipelines/template/depls-pipeline.yml'].each do |filename|
  # set_pipeline(target_name: target_name, name: name, cmd: "erb dependencies=#{tmp_yml_file.path} #{filename}")
  puts "processing #{filename}"
  puts output=ERB.new(File.read(filename)).result()
  # erb(filename, all_dependencies)
  pipeline_name= filename.split("/").last()
  puts "Pipeline name #{pipeline_name}"
  aPipeline=File.new("pipelines/#{depls}-generated.yml", "w")
  aPipeline << output
end


Dir['pipelines/template/cf-apps-pipeline.yml'].each do |filename|
  # set_pipeline(target_name: target_name, name: name, cmd: "erb dependencies=#{tmp_yml_file.path} #{filename}")
  puts "processing #{filename}"
  puts output=ERB.new(File.read(filename)).result()
  # erb(filename, all_dependencies)
  pipeline_name= filename.split("/").last().chomp("-pipeline.yml")
  pipeline_name= "#{depls}-#{pipeline_name}-generated.yml"

  puts "Pipeline name #{pipeline_name}"
  aPipeline=File.new("pipelines/#{pipeline_name}", "w")
  aPipeline << output
end


puts "### WARNING ### no cf app deployment detected. Please check a valid enable-cf-app.yml exists" if all_cf_apps.empty?
puts "### WARNING ### no gitsubmodule detected" if git_submodules.empty?
puts
puts 'Thanks, Orange CloudFoundry SKC'
