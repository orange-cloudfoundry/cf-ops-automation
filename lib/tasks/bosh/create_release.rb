module Tasks
  module Bosh
    # holds bosh list deployments command
    class CreateRelease < Executor
      # [create-release command options]
      # --dir=               Release directory path if not current working directory (default: .)
      # --name=              Custom release name
      # --version=           Custom release version (e.g.: 1.0.0, 1.0-beta.2+dev.10)
      # --timestamp-version  Create release with the timestamp as the dev version (e.g.: 1+dev.TIMESTAMP)
      # --final              Make it a final release
      # --tarball=           Create release tarball at path (e.g. /tmp/release.tgz)
      # --force              Ignore Git dirty state check
      def execute(name:, version:, tarball_path:, dir: '.', final: true, force: false, timestamp_version: false)
        raise "Missing required parameter: name:#{name}, version: #{version} or tarball_path: #{tarball_path}" if name.to_s.empty? || version.to_s.empty? || tarball_path.to_s.empty?

        dir_option = "--dir='#{dir}' "
        timestamp_option = timestamp_version ? "--timestamp-version " : ""
        final_option = final ? "--final " : ""
        tarball_option = "--tarball='#{File.join(tarball_path, name)}-#{version}.tgz' "
        force_option = force ? "--force " : ""
        release_file = File.join(dir, 'releases', name, "#{name}-#{version}.yml")
        bosh_command_options = dir_option + timestamp_option + final_option + tarball_option + force_option + release_file
        puts "Creating release: #{bosh_command}#{bosh_command_options}"
        self.class.run_command(bosh_command + bosh_command_options)
      end

      def bosh_command
        "bosh --non-interactive --json create-release "
      end
    end
  end
end
