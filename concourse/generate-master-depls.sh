#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'


depls = 'master-depls'


version_reference = YAML.load_file( '../' + depls + '/master-depls-versions.yml' )

#public_config = YAML.load_file("../master-depls/master-depls-versions.yml")



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

  puts system(%{bash -c "echo fly -t #{target_name} set-pipeline \
    -p #{PIPELINE_PREFIX}#{name} \
    -c <(#{cmd}) \
    -l public-config.yml \
    #{load.collect { |l| "-l #{l}" }.join(' ')}
  "})
end

#def update_standard_pipelines(target_name, full_config)
#  header('For standard pipelines')
#  Dir['pipelines/*.yml'].each do |filename|
#    name = File.basename(filename, '.yml')
#    set_pipeline(target_name: target_name, name: name, cmd: "erb organization=#{full_config["buildpacks-github-org"]} run_oracle_php_tests=#{full_config['run-oracle-php-tests']} #{filename}")
#  end
#end

def update_bosh_lite_pipelines(target_name, full_config)
  header('For bosh-lite pipelines')
  Dir['config/bosh-lite/*.yml'].each do |filename|
    next if OPTIONS.has_key?(:template) && !filename.include?(OPTIONS[:template])
    deployment_name = File.basename(filename, '.yml')
    full_deployment_name = YAML.load_file(filename)['deployment-name']
    matches = /(lts|edge)\-\d+(\-azure)?/.match(deployment_name)
    if matches.nil?
      puts 'Your config/bosh-lite/*.yml files must be named in the following manner: edge-1.yml, edge-2.yml, lts-1.yml, lts-2.yml, etc.'
      exit 1
    end
    cf_version_type = matches[1]
    set_pipeline(
      target_name: target_name,
      name: deployment_name,
#      cmd: "erb domain_name='full_config["domain-name"]}' deployment_name=#{deployment_name} full_deployment_name=#{full_deployment_name} pipelines/templates/bosh-lite-cf-#{cf_version_type}.yml",
      load: [filename]
    )
  end
end

def update_buildpack_pipelines(target_name, full_config)
  header('For buildpack pipelines')
  Dir['config/buildpack/*.yml'].each do |filename|
    next if OPTIONS.has_key?(:template) && !filename.include?(OPTIONS[:template])

    language = File.basename(filename, '.yml')
    set_pipeline(
      target_name: target_name,
      name: "#{language}-buildpack",
      cmd: "erb language=#{language} organization=#{full_config["buildpacks-github-org"]} pipelines/templates/buildpack.yml",
      load: [filename]
    )
  end
end

#if !OPTIONS.has_key?(:template)
#  update_standard_pipelines(target_name, full_config)
#end
#update_bosh_lite_pipelines(target_name, full_config)


all_dependencies= []

Dir["../" + depls + '/*'].select{|f| File.directory? f}.each do |filename|
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
#    name = File.basename(filename, '.yml')
#    set_pipeline(target_name: target_name, name: name, cmd: "erb organization=#{full_config["buildpacks-github-org"]} run_oracle_php_tests=#{full_config['run-oracle-php-tests']} #{filename}")
end
#puts "##############################"
#    all_dependencies.each do |aDep|
#        puts aDep
#    end
#puts "##############################"
puts YAML.dump(all_dependencies)


update_buildpack_pipelines(target_name, full_config)

puts 'Thanks, OO'
