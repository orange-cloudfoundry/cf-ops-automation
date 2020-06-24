require 'yaml'
require_relative '../utils/coa_logger'
require_relative '../../active_support_copy_deep_merge'

module Coa
  module EnvBootstrapper
    # This class represents the config given by the user at the time of creation
    # of the environment by the bootstrapper.
    class Prereqs
      CONFIGS_LIST = %(bosh bucc concourse cloud_config git_server_manifest inactive_steps pipeline_vars stemcell cf).freeze

      include Coa::Utils::CoaLogger

      attr_reader :bosh, :bucc, :concourse, :cloud_config, :git_server_manifest, :inactive_steps, :pipeline_vars, :stemcell, :cf

      def initialize(prereqs_config = {})
        @bosh                = prereqs_config["bosh"]
        @bucc                = prereqs_config["bucc"]
        @concourse           = prereqs_config["concourse"]
        @cloud_config        = prereqs_config["cloud_config"] || {}
        @git_server_manifest = prereqs_config["git_server_manifest"] || {}
        @inactive_steps      = prereqs_config["inactive_steps"] || []
        @pipeline_vars       = prereqs_config["pipeline_vars"] || {}
        @stemcell            = prereqs_config["stemcell"] || {}
        @cf                  = prereqs_config["cf"] || {}
      end

      def self.new_from_paths(prereqs_paths)
        prereqs_config = prereqs_paths.inject({}) do |ps, path|
          ps.deep_merge(YAML.load_file(path))
        end
        new(prereqs_config)
      end

      def inactive_step?(step)
        inactive_steps.include?(step)
      end

      def to_s
        {
          inactive_steps:      inactive_steps,
          bucc:                bucc,
          stemcell:            stemcell,
          cloud_config:        cloud_config,
          bosh:                bosh,
          git_server_manifest: git_server_manifest,
          concourse:           concourse,
          pipeline_vars:       pipeline_vars,
          cf:                  cf
        }
      end
    end
  end
end
