require 'yaml'
require_relative 'active_support_copy_deep_merge'

# This class add information defined in root_deployment_versions (from root-deployment.yml) to root deployment overview (from deployment-dependencies*.yml)
class RootDeploymentOverviewEnhancer
  attr_reader :root_deployment_name, :root_deployment_overview, :root_deployment_versions

  def initialize(root_deployment_name, root_deployment_overview = {}, root_deployment_versions = {})
    @root_deployment_name = root_deployment_name
    @root_deployment_overview = root_deployment_overview
    @root_deployment_versions = root_deployment_versions

    raise 'invalid root_deployment_name' if @root_deployment_name.to_s.empty?
    raise 'invalid root_deployment_overview' unless @root_deployment_overview
    raise 'invalid root_deployment_versions' unless @root_deployment_versions
  end

  def enhance
    overview = @root_deployment_overview.dup
    overview.each do |_deployment_name, deployment_info|
      next unless deployment_info

      update_releases(deployment_info)
    end

    puts "Enhanced root deployment:\n #{overview.to_yaml}"
    overview
  end

  private

  def update_releases(deployment_info)
    releases = deployment_info.dig('releases') || {}
    releases.each do |release_name, info|
      info_from_versions = @root_deployment_versions.dig('releases', release_name)
      info.delete_if { |key, value| key == 'base_location' && value.start_with?('https://bosh.io/d/github.com') }
      releases[release_name] = info_from_versions.deep_merge(info) if info_from_versions
    end
    deployment_info['releases'] = releases
  end
end
