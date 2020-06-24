#!/usr/bin/env ruby
require 'yaml'
require_relative '../../lib/deployment_deployers_config'
require_relative '../../lib/coa_upgrader'

class RootDeploymentFile
  attr_reader :releases, :stemcell, :name

  def initialize(name, releases = {})
    @name = name
    @releases = releases
    @stemcell = {}
  end

  def to_yaml
    # puts @releases.sort.to_h
    YAML.dump({ 'name' => @name, 'releases' => @releases.sort.to_h, 'stemcell' => @stemcell })
  end

  def update_stemcell_version(version)
    return if version.to_s.empty?

    @stemcell['version'] = version
  end

  def update_stemcell_sha1(sha1)
    return if sha1.to_s.empty?

    @stemcell['sha1'] = sha1
  end

  def update_release_sha1(release_name, sha1)
    return if sha1.to_s.empty?

    release = @releases[release_name] || {}
    release['sha1'] = sha1.to_s
    @releases[release_name] = release
  end

  def update_release_version(release_name, version)
    return if version.to_s.empty?

    puts "Updating #{release_name}"
    release = @releases[release_name] || {}
    release['version'] = version.to_s
    @releases[release_name] = release
  end

  def update_release_base_location(release_name, base)
    return if base.to_s.empty?

    skip_base_location_update = !base.start_with?("https://github.com")
    release = @releases[release_name.to_s] || {}
    if skip_base_location_update
      release['base_location'] = base
    else
      release.delete('base_location')
    end
    @releases[release_name] = release
  end

  def update_release_repository(release_name, repo)
    return if repo.to_s.empty?

    release = @releases[release_name] || {}
    release['repository'] = repo
    @releases[release_name] = release
  end

  def remove_incomplete_release
    removed = []
    @releases.delete_if do |release, details|
      removed << release if details.size <= 1
      details.size <= 1
    end
    puts "Incomplete releases defined in #{@name}: #{removed.join(',')}"
    removed
  end
end

def migrate_to_root_deployment_yml(paas_template_root)
  root_deployment_migrated = 0
  incomplete_releases = {}
  root_deployments_path = Dir["#{paas_template_root}/*-depls"]
  puts root_deployments_path

  root_deployments_path.each do |path|
    root_deployment_name = File.basename(path)
    versions_file = File.join(path, "#{root_deployment_name}-versions.yml")
    versions = YAML.load_file(versions_file)

    root_deployment_file = RootDeploymentFile.new(root_deployment_name, versions.fetch('releases', {}))
    versions.delete('deployment-name')
    stemcell_version = versions.delete('stemcell-version')
    root_deployment_file.update_stemcell_version(stemcell_version.to_s)
    versions.each do |item, value|
      puts "Versions: processing #{item}"
      case item
      when /^(.*)-sha1/
        release_name = Regexp.last_match(1)
        root_deployment_file.update_release_sha1(release_name, value)
      when /^(.*)-version/
        release_name = Regexp.last_match(1)
        root_deployment_file.update_release_version(release_name, value)
      end
    end

    deployment_dependencies_files = Dir["#{path}/**/deployment-dependencies*.yml"]
    puts deployment_dependencies_files
    deployment_dependencies_files.each do |deployment_dependencies_file_path|
      puts "processing #{deployment_dependencies_file_path}"

      unless File.exist?(deployment_dependencies_file_path)
        puts "WARNING - File does not exist: skipping #{deployment_dependencies_file_path}"
        next
      end
      deployment_dependencies = YAML.load_file(deployment_dependencies_file_path)
      deployment_dependencies_releases = deployment_dependencies.dig('deployment').values.first['releases']
      next unless deployment_dependencies_releases

      deployment_dependencies_releases.each do |release, details|
        root_deployment_file.update_release_repository(release, details.dig('repository'))
        updated_base_location = details.dig('base_location').gsub(%r(bosh.io/d/), '')
        root_deployment_file.update_release_base_location(release, updated_base_location)
      end
    end

    root_deployment_incomplete_releases = root_deployment_file.remove_incomplete_release
    incomplete_releases[root_deployment_file.name] = root_deployment_incomplete_releases unless root_deployment_incomplete_releases.empty?
    filepath = File.join(path, 'root-deployment.yml')
    File.open(filepath, 'w+') { |file| file.write(root_deployment_file.to_yaml) }
    root_deployment_migrated += 1
  end
  [root_deployment_migrated, incomplete_releases]
end

config_path = ARGV[0]
paas_template_root = ARGV[1]
puts "Config path: #{config_path} - Templates path: #{paas_template_root}"

raise "invalid paas_template_root: <#{paas_template_root}> does not exist" unless Dir.exist?(paas_template_root)

migrated_count, incomplete_releases = migrate_to_root_deployment_yml(paas_template_root)

puts "Done"

unless incomplete_releases.empty?
  puts "Please add missing info "
  puts incomplete_releases.to_yaml
end

puts
puts 'Summary:'
puts "  #{migrated_count} root deployment migrated"
puts

puts
puts 'Thanks, Orange CloudFoundry SKC'
