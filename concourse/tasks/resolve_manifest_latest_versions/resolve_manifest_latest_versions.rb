require 'yaml'

class ResolveManifestLatestVersions
  attr_reader :deployment_name, :manifest_file

  def initialize(deployment_name, manifest, output_dir = "./result-dir")
    @deployment_name = deployment_name
    @manifest = manifest
    @output_dir = output_dir
  end

  def process(versions, stemcell_name)
    resolved_manifest = @manifest.dup
    lock_releases_versions(resolved_manifest, versions)
    lock_stemcells_version(resolved_manifest, stemcell_name, versions)

    output_filename = File.join(@output_dir, "#{@deployment_name}.yml")
    File.open(output_filename, 'w') { |file| file.write(YAML.dump(resolved_manifest)) }
  end

  private

  def lock_stemcells_version(resolved_manifest, stemcell_name, versions)
    resolved_manifest['stemcells']&.each do |stemcell|
      os = stemcell.dig('os')
      version = stemcell.dig('version')
      if version == 'latest'
        lock_version = versions.dig('stemcell', 'version')
        raise "Missing version for stemcell #{stemcell_name}. Please fix 'root-deployment.yml' or this manifest" if lock_version.to_s.empty?

        if stemcell_name.include?(os)
          stemcell.store('version', lock_version)
        else
          puts "Manifest does not match expected os (#{os}) for stemcell #{stemcell_name}"
        end
      else
        puts "Ignoring release #{name} as not set to latest (found: #{version})"
      end
    end
  end

  def lock_releases_versions(resolved_manifest, versions)
    resolved_manifest['releases']&.each do |release|
      name = release.dig('name')
      version = release.dig('version')
      if version == 'latest'
        lock_version = versions.dig('releases', name, 'version')
        raise "Missing version for release #{name}. Please fix 'root-deployment.yml' or this manifest" if lock_version.to_s.empty?

        release.store('version', lock_version)
      else
        puts "Ignoring release #{name} as not set to latest (found: #{version})"
      end
    end
  end
end
