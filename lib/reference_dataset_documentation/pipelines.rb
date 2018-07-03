require 'securerandom'
require 'fileutils'
require 'tmpdir'
require 'open3'

module ReferenceDatasetDocumentation
  class Pipelines
    attr_reader :generator, :generated_pipelines_dir
    REFERENCE_DATASET_OUTPUT_PATH = 'docs/reference_dataset'.freeze

    def initialize(generator, output_dir = REFERENCE_DATASET_OUTPUT_PATH)
      @generator = generator
      @generated_pipelines_dir = output_dir
    end

    def generate
      `ruby #{PROJECT_ROOT_DIR}/scripts/generate-depls.rb -o #{generated_pipelines_dir} \
-p #{generator.config_repo_path} -t #{generator.template_repo_path} \
-d #{generator.root_deployment_name}`
    end

    def validate
      Dir["#{@generated_pipelines_dir}/pipelines/*-generated.yml"].each do |pipeline_filename|
        command = "fly validate-pipeline -c ./#{pipeline_filename} --strict"
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

    def write_credentials_pipeline_list
      generator.add "## List of pipelines in which credentials appear for #{generator.root_deployment_name}", ""

      credentials_pipeline_list.sort.each do |credential, pipelines|
        write_credential_pipeline_list(credential, pipelines)
      end
    end

    def write_pipelines_credential_list
      generator.add "## Required pipeline credentials for #{generator.root_deployment_name}", ""

      pipelines_credential_list.sort.each do |pipeline_name, pipe_creds|
        write_pipeline_credential_list(pipeline_name, pipe_creds)
      end
    end

    def self.cleanup_generation_dir(location = REFERENCE_DATASET_OUTPUT_PATH)
      generated_pipelines_filter = File.join(location, 'pipelines', '*-generated.yml')
      pipelines_to_delete = Dir.glob(generated_pipelines_filter)
      FileUtils.rm_rf(pipelines_to_delete)
    end

    def self.generated_pipeline_names
      path = File.join(PROJECT_ROOT_DIR, 'concourse', 'pipelines', 'template', '*.yml.erb')

      Dir[path].map do |file|
        filename = File.basename(file)
        filename == "depls-pipeline.yml.erb" ? "" : filename.gsub('-pipeline.yml.erb', '-')
      end
    end

    private

    def pipelines_credential_list
      @pipelines_credential_list ||= begin
        pipe_creds = {}

        generated_pipeline_paths.each do |path|
          pipeline_content = File.read(path)
          creds_list = pipeline_content.scan(/\(\(([\w|-]*)\)\)/).flatten.uniq
          pipeline_name = File.basename(path)
          pipe_creds[pipeline_name] = creds_list
        end

        pipe_creds
      end
    end

    def credentials_pipeline_list
      creds_pipe_list = Hash.new { |h, k| h[k] = [] }

      pipelines_credential_list.each do |pipeline_name, pipe_creds|
        pipe_creds.each do |cred|
          creds_pipe_list[cred] << pipeline_name
        end
      end

      creds_pipe_list
    end

    def generated_pipeline_paths
      self.class.generated_pipeline_names.map do |generated_file|
        "#{generated_pipelines_dir}/pipelines/#{generator.root_deployment_name}-#{generated_file}generated.yml"
      end
    end

    def write_pipeline_credential_list(pipeline_name, pipe_creds)
      generator.add("### #{pipeline_name}", "")

      if pipe_creds.empty?
        generator.add("No credentials required", "")
      else
        pipe_creds.sort.each { |cred| generator.add("* #{cred}") }
        generator.add ""
      end
    end

    def write_credential_pipeline_list(credential, pipelines)
      generator.add("### #{credential}", "")

      pipelines.uniq.sort.each { |pipeline| generator.add("* #{pipeline}") }
      generator.add ""
    end
  end
end
