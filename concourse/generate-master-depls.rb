#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'
require 'optparse'
require 'tempfile'
require 'erb'
require 'ostruct'


# Argument parsing
OPTIONS = {}
opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: ./bin/update-all-the-pipelines [options]"

  opts.on("--without=WITHOUT", "-wWITHOUT", "Don't update matched pipelines") do |without_string|
    OPTIONS[:without] = without_string
  end

  opts.on("--match=MATCH", "-mMATCH", "Only update matched pipelines") do |match_string|
    OPTIONS[:match] = match_string
  end

  opts.on("--template=TEMPLATE", "-tTEMPLATE", "Only update pipelines from the specified template") do |template_string|
    OPTIONS[:template] = template_string
  end
end
opt_parser.parse!


depls = 'master-depls'


version_reference = YAML.load_file( '../' + depls + '/master-depls-versions.yml' )

#public_config = YAML.load_file("../master-depls/master-depls-versions.yml")

def erb(template, vars)
#puts vars
  puts ERB.new(template).result(OpenStruct.new(vars).instance_eval { binding })
#  ERB.new(template).result()
end

#full_config = public_config.merge(lpass_config)
full_config = version_reference
puts full_config

flyrc  = YAML.load_file(File.expand_path('~/.flyrc'))
target_name= ENV['TARGET_NAME'] || "cw-pp-micro"
target = flyrc['targets'][target_name]
concourse_url= target['api']

PIPELINE_PREFIX = ENV['PIPELINE_PREFIX'] || ''

def header(msg)
  print '*' * 10
  puts " #{msg}"
end

def set_pipeline(target_name:,name:, cmd:, load: [])
  return if OPTIONS.has_key?(:match) && !name.include?(OPTIONS[:match])
  return if OPTIONS.has_key?(:without) && name.include?(OPTIONS[:without])
  puts "   #{name} pipeline"

#  puts system(%{bash -c "echo fly -t #{target_name} set-pipeline \
#    -p #{PIPELINE_PREFIX}#{name} \
#    -c <(#{cmd})
    puts "#{cmd}"
   puts system(%{bash -c "<(#{cmd})"})


 #   #{load.collect { |l| "-l #{l}" }.join(' ')}
#    -l public-config.yml \
end



#if !OPTIONS.has_key?(:template)
#  update_standard_pipelines(target_name, full_config)
#end
#update_bosh_lite_pipelines(target_name, full_config)

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

#filename=File.open("pipelines/template/depls-pipeline.yml")
name="#{depls}-pipeline"

#tmp_yml_file=Tempfile.new('dependencies.yml')
#tmp_yml_file=File.new('dependencies.yml',"w")
#tmp_yml_file << all_dependencies.to_yaml
#tmp_yml_file.flush
#tmp_yml_file.close

all_dependencies=generate_deployment_overview_from_hash("../" + depls + '/*',version_reference)

Dir['pipelines/template/depls-pipeline.yml'].each do |filename|
    # set_pipeline(target_name: target_name, name: name, cmd: "erb dependencies=#{tmp_yml_file.path} #{filename}")
    puts output=ERB.new(File.read(filename)).result()
    # erb(filename, all_dependencies)
    aPipeline=File.new("pipelines/#{depls}-generated.yml", "w")
    aPipeline << output

end



puts 'Thanks, Orange CloudFoundry SKC'
