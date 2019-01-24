require_relative '../utils/coa_logger'

module Coa
  module ReferenceDatasetDocumentation
    # This class is an abstract class for all writers.
    module ReadmeAuthor
      include Coa::Utils::CoaLogger
      attr_reader :root_deployment_name, :readme_path, :config_repo_path, :template_repo_path, :pipelines

      def initialize(config)
        @root_deployment_name = config.root_deployment_name
        @readme_path          = config.readme_path
        @config_repo_path     = config.config_repo_path
        @template_repo_path   = config.template_repo_path
        @pipelines            = config.pipelines
      end

      def write(*inputs)
        File.open(readme_path, 'a') do |file|
          inputs.each { |input| file.puts input.to_s }
        end
      end
    end
  end
end
