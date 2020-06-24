module Tasks
  # ease paas templates repository manipulations
  module TemplatesRepo
    require 'yaml'
    #
    class RootDeployment
      attr_reader :releases, :stemcell

      DEFAULT_GIT_URL = 'https://github.com/'.freeze

      def initialize(name, basedir)
        raise InvalidTaskParameter, "Error: missing root deployment name ('#{name}') or base_dir ('#{basedir}')" if name.to_s.empty? || basedir.to_s.empty?

        root_deployment_file = File.join(basedir, name, 'root-deployment.yml')
        root_deployment_loaded = if File.exist?(root_deployment_file)
                                   YAML.load_file(root_deployment_file) || {}
                                 else
                                   {}
                                 end
        @releases = root_deployment_loaded.dig('releases') || {}
        add_default_base_location
        @stemcell = root_deployment_loaded.dig('stemcell') || {}
      end

      def releases_git_urls
        urls = {}
        @releases.delete_if { |_name, details| details['repository'].to_s.empty? }
          .each do |name, details|
            url = details['base_location'].to_s
            url += '/' unless url.end_with?('/')
            url += details['repository'].to_s
            urls[name] = url
          end
        urls
      end

      def release_version(name)
        @releases.dig(name, 'version')
      end

      def release(name)
        @releases.dig(name)
      end

      private

      def add_default_base_location
        @releases.map do |_name, details|
          details.store('base_location', DEFAULT_GIT_URL) unless details['base_location']
          details
        end
      end
    end
  end
end

