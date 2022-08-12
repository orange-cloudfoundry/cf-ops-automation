module Tasks
  # ease paas templates repository manipulations
  module TemplatesRepo
    require 'yaml'
    # ease processing of 'root-deployment.yml'
    class RootDeployment
      attr_reader :releases, :stemcell

      DEFAULT_GIT_URL = 'https://github.com/'.freeze
      DEFAULT_TAG_PREFIX = 'v'.freeze
      DEFAULT_SKIP_CHECKOUT = true

      def initialize(name, basedir)
        raise InvalidTaskParameter, "Error: missing root deployment name ('#{name}') or base_dir ('#{basedir}')" if name.to_s.empty? || basedir.to_s.empty?

        root_deployment_loaded = load_root_deployment_yml(basedir, name)
        @releases = root_deployment_loaded.dig('releases') || {}
        add_default_values
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

      def release_tag_prefix(name)
        @releases.dig(name, 'tag_prefix') || DEFAULT_TAG_PREFIX
      end

      def release_skip_branch_checkout(name)
        value = @releases.dig(name, 'skip_branch_checkout')
        value.nil? ? DEFAULT_SKIP_CHECKOUT : value
      end

      private

      def load_root_deployment_yml(basedir, name)
        root_deployment_file = File.join(basedir, name, 'root-deployment.yml')
        if File.exist?(root_deployment_file)
          YAML.load_file(root_deployment_file, aliases: true) || {}
        else
          {}
        end
      end

      def add_default_values
        @releases.map do |_name, details|
          add_default_base_location(details)
          add_default_tag_prefix(details)
          add_default_skip_checkout(details)
        end
      end

      def add_default_base_location(details)
        details.store('base_location', DEFAULT_GIT_URL) unless details['base_location']
      end

      def add_default_tag_prefix(details)
        details.store('tag_prefix', DEFAULT_TAG_PREFIX) unless details['tag_prefix']
        details
      end

      def add_default_skip_checkout(details)
        details.store('skip_branch_checkout', DEFAULT_SKIP_CHECKOUT) unless details.include?('skip_branch_checkout')
        details
      end
    end
  end
end

