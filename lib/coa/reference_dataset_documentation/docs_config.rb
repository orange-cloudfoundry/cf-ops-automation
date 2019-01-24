require_relative './pipelines'
require_relative './readme'

module Coa
  module ReferenceDatasetDocumentation
    # This class holds the config to generate and validate documentation from
    # the reference dataset.
    class DocsConfig
      attr_reader :root_deployment_name, :config_repo_name, :template_repo_name, :documentation_path, :readme_filename

      def initialize(root_deployment_name:, config_repo_name:, template_repo_name:, documentation_path:, readme_filename: 'readme.md')
        @root_deployment_name  = root_deployment_name
        @config_repo_name      = config_repo_name
        @template_repo_name    = template_repo_name
        @readme_filename       = readme_filename
        @documentation_path    = documentation_path
      end

      def pipelines
        Coa::ReferenceDatasetDocumentation::Pipelines.new(self)
      end

      def readme
        Coa::ReferenceDatasetDocumentation::Readme.new(self)
      end

      def readme_path
        File.join(documentation_path, readme_filename)
      end

      def config_repo_path
        File.join(documentation_path, config_repo_name)
      end

      def template_repo_path
        File.join(documentation_path, template_repo_name)
      end

      def generated_pipeline_list
        @generated_pipeline_list ||=
          begin
            pattern = "#{documentation_path}/pipelines/*-generated.yml"
            Dir.glob(pattern)
          end
      end

      def cleanup_generated_pipelines
        FileUtils.rm_rf(generated_pipeline_list)
      end

      def self.cleanup_generated_pipelines(dir)
        pattern = "#{dir}/pipelines/*-generated.yml"
        generated_pipeline_list = Dir.glob(pattern)
        FileUtils.rm_rf(generated_pipeline_list)
      end
    end
  end
end
