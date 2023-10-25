require 'open3'
require_relative '../constants'

module Coa
  module ReferenceDatasetDocumentation
    # This class represents the pipelines contained in the documenation.
    class Pipelines
      include Coa::Constants

      attr_reader :config_repo_path,
                  :generated_pipeline_list,
                  :output_path,
                  :root_deployment_name,
                  :template_repo_path

      def initialize(docs_config)
        @config_repo_path        = docs_config.config_repo_path
        @generated_pipeline_list = docs_config.generated_pipeline_list
        @output_path             = docs_config.documentation_path
        @root_deployment_name    = docs_config.root_deployment_name
        @template_repo_path      = docs_config.template_repo_path
      end

      def generate
        output_option = "-o #{output_path}"
        config_option = "-p #{config_repo_path}"
        templates_option = "-t #{template_repo_path}"
        depls_option = "-d #{root_deployment_name}"
        iaas_type_option = "--iaas openstack"
        profiles_option = "--profiles vault-profile"

        command = "ruby #{PROJECT_ROOT_DIR}/scripts/generate-depls.rb #{output_option} "
        command += "#{config_option} #{templates_option} #{depls_option} #{iaas_type_option} #{profiles_option}"

        puts "Executing: #{command}"
        puts`#{command}`
      end

      def validate
        generated_pipeline_list.each do |pipeline_filename|
          puts "validating #{pipeline_filename}"
          command = "fly validate-pipeline -c #{pipeline_filename} --var=stemcell-main-name=my-stemcell-name"
          stdout_str, stderr_str, = Open3.capture3(command)
          raise "Invalid generated pipeline (#{pipeline_filename}): #{stderr_str}" unless stderr_str.empty?
          raise "Invalid generated pipeline (#{pipeline_filename}): #{stdout_str}" unless stdout_str == "looks good\n"
        end
      end

      def are_present?
        generated_pipeline_paths.all? do |path|
          File.exist?(path)
        end
      end

      def generated_pipeline_paths
        coa_pipeline_names.map do |generated_file|
          "#{output_path}/pipelines/#{generated_file}.yml"
        end
      end

      def coa_pipeline_names
        pattern = "#{PROJECT_ROOT_DIR}/concourse/pipelines/template/*.yml.erb"

        Dir[pattern].map do |file|
          filename = File.basename(file)
          basename = filename.gsub('-pipeline.yml.erb', '-')
          "#{root_deployment_name}-#{basename}generated"
        end
      end
    end
  end
end
