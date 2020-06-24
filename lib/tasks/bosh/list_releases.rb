module Tasks
  module Bosh
    # holds bosh list deployments command
    class ListReleases < Executor
      def execute
        releases = {}
        result = self.class.run_command(bosh_command)
        raw_deployments = self.class.rows(result)
        raw_deployments&.each do |release|
          update_releases(release, releases)
        end
        releases
      end

      def bosh_command
        "bosh releases --json"
      end

      private

      def update_releases(a_release, all_releases)
        name = a_release&.dig('name')
        version = a_release&.dig('version')
        is_deployed = version.end_with?('*')
        as_uncommitted_changes = version.end_with?('+')
        commit = a_release&.dig('commit_hash')
        versions = all_releases[name] || {}
        current_version = version.delete_suffix('+').delete_suffix('*')
        properties = versions.dig(name, current_version) || {}
        properties[:commit_hash] = commit
        properties[:deployed] = is_deployed
        properties[:uncommitted_changes] = as_uncommitted_changes
        versions.store(current_version, properties)
        all_releases.store(name, versions) unless name.nil?
      end
    end
  end
end
