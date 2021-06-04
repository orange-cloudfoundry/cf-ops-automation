require 'yaml'

# Abstract class to resolve bosh release url
class AbstractReleaseUrlResolver
  attr_reader :download_server_url

  def initialize(config)
    @config = config
    @download_server_url = config.dig('DOWNLOAD_SERVER_URL') || ''
  end

  # This method should be use by children to determine if it is possible to get a download url for a bosh release using fields provided by constructor
  def accept?
    false
  end

  # Perform some validation
  def valid?
    !@download_server_url.empty?
  end

  def resolve(_release_name, _release_version, _release_repository)
    raise NotImplementedError('This method must be overridden')
  end

  def true?(object)
    object.to_s.casecmp('true').zero?
  end
end

# Generate a bosh release url in Bosh.io format
class BoshIoReleaseUrlResolver < AbstractReleaseUrlResolver
  def initialize(config)
    super
    @offline_mode_enabled = true?(config.dig('OFFLINE_MODE_ENABLED'))
  end

  def accept?
    online_mode = @offline_mode_enabled == false
    online_mode
  end

  def resolve(release_name, release_version, release_repository)
    return {} unless valid?

    # Bosh download url format:   https://bosh.io/d/github.com/cloudfoundry/syslog-release?v=11
    puts "Resolving #{release_name}-#{release_version} using Bosh IO resolver"
    resolved_url = "#{download_server_url.delete_suffix('/')}/#{release_repository}?v=#{release_version}"
    { 'url' => resolved_url }
  end
end

# Generate a bosh release url in our expected S3 format
class OfflineReleaseUrlResolver < AbstractReleaseUrlResolver
  def initialize(config)
    super
    @offline_mode_enabled = true?(config.dig('OFFLINE_MODE_ENABLED'))
    @precompile_mode_enabled = true?(config.dig('PRECOMPILE_MODE_ENABLED'))
  end

  def accept?
    @offline_mode_enabled && @precompile_mode_enabled == false
  end

  def resolve(release_name, release_version, release_repository)
    return {} unless valid?

    # Minio download url format:  https://private-s3.internal.paas/bosh-releases/minio/minio-2020-06-18T02-23-35Z.tgz
    puts "Resolving #{release_name}-#{release_version} using Offline resolver"
    namespace = release_repository.split('/').first
    resolved_url = "#{download_server_url.delete_suffix('/')}/#{namespace}/#{release_name}-#{release_version}.tgz"
    { 'url' => resolved_url, 'sha1' => '' }
  end

  def valid?
    super && !@offline_mode_enabled.to_s.empty? && !@precompile_mode_enabled.to_s.empty?
  end
end

# Generate a bosh release url in our expected S3 format compiled releases
class PrecompileOfflineReleaseUrlResolver < AbstractReleaseUrlResolver
  def initialize(config)
    super
    @offline_mode_enabled = true?(config&.dig('OFFLINE_MODE_ENABLED'))
    @precompile_mode_enabled = true?(config&.dig('PRECOMPILE_MODE_ENABLED'))
    @stemcell_os = config&.dig('STEMCELL_OS') || ''
    @stemcell_version = config&.dig('STEMCELL_VERSION') || ''
  end

  def accept?
    @offline_mode_enabled && @precompile_mode_enabled
  end

  def resolve(release_name, release_version, release_repository)
    return {} unless valid?

    # Minio download url format for compiled release:  https://private-s3.internal.paas/compiled-releases/minio/minio-2020-06-18T02-23-35Z-ubuntu-bionic-621.89.tgz
    puts "Resolving #{release_name}-#{release_version} using Compiled Offline resolver"
    namespace = release_repository.split('/').first
    resolved_url = "#{download_server_url.delete_suffix('/')}/#{namespace}/#{release_name}-#{release_version}-#{@stemcell_os}-#{@stemcell_version}.tgz"
    { 'url' => resolved_url, 'sha1' => '', 'stemcell' => { 'os' => @stemcell_os, 'version' => @stemcell_version }, 'exported_from' => [{ 'os' => @stemcell_os, 'version' => @stemcell_version }] }
  end

  def valid?
    super && !@offline_mode_enabled.to_s.empty? && !@precompile_mode_enabled.to_s.empty? && !@stemcell_os.to_s.empty? && !@stemcell_version.to_s.empty?
  end
end

# Factory to create resolver
class ResolveManifestReleaseUrlFactory
  def self.factory(config = ENV.to_h.dup)
    resolvers = []
    resolvers << PrecompileOfflineReleaseUrlResolver.new(config)
    resolvers << OfflineReleaseUrlResolver.new(config)
    resolvers << BoshIoReleaseUrlResolver.new(config)
    new(resolvers)
  end

  def initialize(resolvers)
    @resolvers = resolvers
  end

  def select_resolver
    @resolvers.each do |resolver|
      return resolver if resolver.accept?
    end
    raise 'Cannot find suitable resolver, please check Environment Variables'
  end

  def list_resolver
    @resolvers.dup.freeze
  end
end

# This class processes managed bosh releases defined in a manifest and add a download url foreach.
class ResolveManifestUrls
  attr_reader :deployment_name

  def initialize(deployment_name, release_url_resolver, output_dir = "./result-dir")
    @deployment_name = deployment_name
    @release_url_resolver = release_url_resolver
    @output_dir = output_dir
  end

  def process(manifest, versions)
    resolved_manifest = manifest.dup
    process_release_urls(resolved_manifest, versions)

    output_filename = File.join(@output_dir, "#{@deployment_name}.yml")
    File.open(output_filename, 'w') { |file| file.write(YAML.dump(resolved_manifest)) }
    resolved_manifest
  end

  private

  def process_release_urls(resolved_manifest, all_versions)
    resolved_manifest['releases']&.each do |release|
      name, version_from_manifest = extract_release_manifest_info(release)
      expected_version, repository = extract_version_info(name, all_versions)
      next if latest?(name, version_from_manifest) || !version_managed_by_coa?(name, expected_version, version_from_manifest)

      resolved_url = @release_url_resolver.resolve(name, version_from_manifest, repository)
      puts "Patching #{name}:#{version_from_manifest} url with #{resolved_url}"
      release.merge!(resolved_url)
    end
  end

  def version_managed_by_coa?(name, expected_coa_version, manifest_version)
    if expected_coa_version != manifest_version
      puts "WARNING: This release is not managed by COA. Release: #{name} - Manifest version: #{manifest_version}. Skipping !"
      false
    else
      true
    end
  end

  def latest?(name, version)
    if version == 'latest'
      puts "WARNING: Cannot set download url for a release using 'latest' as version. Release: #{name} - Manifest version: #{version}. Skipping !"
      true
    else
      false
    end
  end

  def extract_version_info(name, all_versions)
    version = all_versions.dig('releases', name, 'version')
    repository = all_versions.dig('releases', name, 'repository')
    [version, repository]
  end

  def extract_release_manifest_info(release)
    name = release.dig('name')
    version = release.dig('version')
    [name, version]
  end
end
