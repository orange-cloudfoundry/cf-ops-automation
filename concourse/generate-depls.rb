#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'
require 'optparse'
require 'tempfile'
require 'erb'
require 'ostruct'

# TODO add rspec file to avoid regression

# Argument parsing
OPTIONS = {}
opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: ./#{opts.program_name} <options>"

  opts.on("-d", "--depls DEPLOYMENT", "Specify a deployment name to generate template for. MANDATORY") do |deployment_string|
    OPTIONS[:depls]= deployment_string
  end

end
opt_parser.parse!


depls = OPTIONS[:depls]
opt_parser.abort("#{opt_parser}") if depls == nil

version_reference = YAML.load_file( "../#{depls}/#{depls}-versions.yml" )

def erb(template, vars)
  puts ERB.new(template).result(OpenStruct.new(vars).instance_eval { binding })
end

def header(msg)
  print '*' * 10
  puts " #{msg}"
end

def generate_deployment_overview_from_array(path, version_reference)
   all_dependencies= []
   Dir[path].select{|f| File.directory? f}.each do |filename|
    dirname= filename.split('/').last
    puts "Processing #{dirname}"
    Dir[filename + "/deployment-dependencies.yml"].each do |dependency_file|
        puts "Bosh release detected: #{dirname}"
        current_dependecies=YAML.load_file(dependency_file)
        current_dependecies["deployment"].each do | aDep|
            raise "#{dependency_file} - Invalid deployment: expected <#{dirname}> - Found <#{aDep["name"]}>" if aDep["name"] != dirname
#            puts aDep["name"]
#            puts aDep["releases"]
            all_dependencies << aDep

            aDep["releases"].each do |aRelease|
#                puts "arelease: #{aRelease}"
                version=version_reference[aRelease['name']+'-version']
                aRelease['version']= version
            end
            raise ""#{dependency_file} - Invalid stemcell: expected <#{version_reference['stemcell-name'}> - Found <#{aDep["stemcells"][0]["name"]}>" if aDep["stemcells"][0]["name"] != version_reference['stemcell-name']
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

    Dir[path].select{|f| File.directory? f}.each do |filename|
        dirname= filename.split('/').last
        puts "Processing #{dirname}"
        Dir[filename + "/deployment-dependencies.yml"].each do |dependency_file|
            puts "Bosh release detected: #{dirname}"
            current_dependecies=YAML.load_file(dependency_file)
            current_dependecies["deployment"].each do | deployment_name, deployment_details|

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
                  puts "####### #{version}"
                  # deployment_details['stemcells'][aStemcell]['version']= version
                end
            end
        end
        #puts "##############################"
        #    all_dependencies.each do |aDep|
        #        puts aDep
        #    end
        #puts "##############################"
        puts YAML.dump(all_dependencies)
    end
        all_dependencies
end


all_dependencies=generate_deployment_overview_from_hash("../" + depls + '/*',version_reference)

Dir['pipelines/template/depls-pipeline.yml'].each do |filename|
    # set_pipeline(target_name: target_name, name: name, cmd: "erb dependencies=#{tmp_yml_file.path} #{filename}")
    puts output=ERB.new(File.read(filename)).result()
    # erb(filename, all_dependencies)
    aPipeline=File.new("pipelines/#{depls}-generated.yml", "w")
    aPipeline << output

end

puts 'Thanks, Orange CloudFoundry SKC'
