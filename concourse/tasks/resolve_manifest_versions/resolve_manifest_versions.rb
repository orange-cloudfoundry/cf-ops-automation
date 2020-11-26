require 'yaml'
# This class ensure versions managed by COA are enforced in bosh manifest
class ResolveManifestVersions
  attr_reader :deployment_name, :manifest_file

  def initialize(deployment_name, manifest, output_dir = "./result-dir")
    @deployment_name = deployment_name
    @manifest = manifest
    @output_dir = output_dir
  end

  def process(versions, stemcell_name)
    resolved_manifest = @manifest.dup
    process_releases_versions(resolved_manifest, versions)
    process_stemcells_version(resolved_manifest, stemcell_name, versions)

    output_filename = File.join(@output_dir, "#{@deployment_name}.yml")
    File.open(output_filename, 'w') { |file| file.write(YAML.dump(resolved_manifest)) }
    resolved_manifest
  end

  private

  def process_stemcells_version(resolved_manifest, stemcell_name, versions)
    resolved_manifest['stemcells']&.each do |stemcell|
      process_stemcell(stemcell, stemcell_name, versions)
    end
  end

  def process_stemcell(stemcell, stemcell_name, versions)
    stemcell_alias, version, os, name = extract_stemcell_manifest_info(stemcell)
    if version == 'latest'
      puts "Extracting stemcell version defined for #{stemcell_alias}##{os || name}"
      lock_version = expected_stemcell_version(stemcell_name, versions)
      lock_stemcell_version(lock_version, stemcell, stemcell_name)
    else
      puts "Ignoring stemcell #{stemcell_alias}##{os || name} as version is not set to latest (version: #{version})"
    end
  end

  def lock_stemcell_version(lock_version, stemcell, stemcell_name)
    stemcell_alias, version, os, name = extract_stemcell_manifest_info(stemcell)
    if os.to_s.empty? || stemcell_name.include?(os)
      puts "Locking stemcell #{stemcell_alias}##{os || name}##{version} to #{lock_version}"
      stemcell.store('version', lock_version)
    else
      puts "Manifest does not match expected os (#{os}) for stemcell #{stemcell_name}. Keeping #{stemcell_alias}##{os || name}##{version}"
    end
  end

  def expected_stemcell_version(stemcell_name, versions)
    target_version = versions.dig('stemcell', 'version')
    raise "Missing version for stemcell #{stemcell_name}. Please fix 'root-deployment.yml' or this manifest" if target_version.to_s.empty?

    target_version
  end

  def extract_stemcell_manifest_info(stemcell)
    stemcell_alias = stemcell.dig('alias')
    version = stemcell.dig('version')
    optional_os = stemcell.dig('os')
    optional_name = stemcell.dig('name')
    [stemcell_alias, version, optional_os, optional_name]
  end

  def process_releases_versions(resolved_manifest, versions)
    resolved_manifest['releases']&.each do |release|
      name, version = extract_release_manifest_info(release)
      lock_version, release_versions_details = extract_expected_info(name, versions)
      puts "WARNING: inconsistent versions detected. Release: #{name} - Manifest version: #{version} - COA expected version: #{lock_version}. Using COA version." if version != 'latest' && lock_version && version != lock_version

      if release_versions_details
        lock_release_version(lock_version, name, release)
      else
        puts "WARNING: Ignoring release #{name}, it is not managed by COA. Please define the release in 'root-deployment.yml', to let COA handle it. Keeping version already defined in manifest: '#{version}'"
      end
    end
  end

  def lock_release_version(lock_version, name, release)
    raise "Missing version for release #{name}. Please fix 'root-deployment.yml' or this manifest" if lock_version.to_s.empty?

    puts "Locking release #{name} to #{lock_version}"
    release.store('version', lock_version)
  end

  def extract_expected_info(name, versions)
    release_versions_details = versions&.dig('releases', name)
    lock_version = release_versions_details&.dig('version')
    [lock_version, release_versions_details]
  end

  def extract_release_manifest_info(release)
    name = release.dig('name')
    version = release.dig('version')
    [name, version]
  end
end
