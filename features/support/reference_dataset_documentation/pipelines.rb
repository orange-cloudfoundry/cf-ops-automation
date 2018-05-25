require 'securerandom'
require 'fileutils'

module ReferenceDatasetDocumentation
  class Pipelines
    attr_reader :generator, :generated_pipelines_dir

    def initialize(generator)
      @generator = generator
      output_name = SecureRandom.uuid
      @generated_pipelines_dir = "#{PROJECT_ROOT_DIR}/features/generated_pipelines/#{output_name}"
    end

    def generate
      `ruby #{PROJECT_ROOT_DIR}/scripts/generate-depls.rb -o #{generated_pipelines_dir} \
-p #{generator.config_repo_path} -t #{generator.template_repo_path} \
-d #{generator.root_deployment_name}`
    end

    def are_ok?
      generated_pipeline_paths.all? do |path|
        File.exist?(path)
      end
    end

    def write_required_credentials
      generator.add "## Required pipeline credentials for #{generator.root_deployment_name}", ""

      generated_pipeline_paths.each do |generated_pipeline_path|
        write_required_credentials_for_pipeline(generated_pipeline_path)
      end
    end

    def delete
      FileUtils.rm_rf(generated_pipelines_dir)
    end

    def self.generated_pipeline_names
      path = File.join(PROJECT_ROOT_DIR, 'concourse', 'pipelines', 'template', '*')

      Dir[path].map do |file|
        filename = File.basename(file)
        filename == "depls-pipeline.yml.erb" ? "" : filename.gsub('-pipeline.yml.erb', '-')
      end
    end

    private

    def generated_pipeline_paths
      self.class.generated_pipeline_names.map do |generated_file|
        "#{generated_pipelines_dir}/pipelines/#{generator.root_deployment_name}-#{generated_file}generated.yml"
      end
    end

    def write_required_credentials_for_pipeline(path)
      generator.add("### #{File.basename(path)}", "")

      pipeline_content = File.read(path)
      required_credentials = pipeline_content.scan(/\(\(([\w|-]*)\)\)/).flatten.uniq
      write_credentials_list_for_pipeline(required_credentials)
    end

    def write_credentials_list_for_pipeline(credentials)
      if credentials.empty?
        generator.add("No credentials required", "")
      else
        credentials.flatten.uniq.each { |cred| generator.add("* #{cred}") }
        generator.add ""
      end
    end
  end
end
