require_relative './writer'
require_relative '../utils/coa_logger'
require 'pathname'

module Coa
  module ReferenceDatasetDocumentation
    # This class is an abstract class for all writers.
    class Writer
      include Coa::Utils::CoaLogger
      attr_reader :root_deployment_name, :readme_path, :config_repo_path, :template_repo_path

      def initialize(config)
        @root_deployment_name = config.root_deployment_name
        @readme_path          = config.readme_path
        @config_repo_path     = config.config_repo_path
        @template_repo_path   = config.template_repo_path
      end

      def add(*inputs)
        File.open(readme_path, 'a') do |file|
          inputs.each { |input| file.puts input.to_s }
        end
      end
    end
  end
end
