module ReferenceDatasetDocumentation
  class Generator
    attr_reader :path,
                :root_deployment_name,
                :example_type,
                :config_repo_name,
                :template_repo_name

    def initialize(params = {})
      check_params(params)
      @root_deployment_name = params[:root_deployment_name]
      @example_type = params[:example_type]
      @config_repo_name = params[:config_repo_name]
      @template_repo_name = params[:template_repo_name]
      @path = File.join(PROJECT_ROOT_DIR, params[:path])
    end

    def perform
      cleanup_document
      write_exhibit_intro
      TreeWriter.new(self).perform
      FileListWriter.new(self).perform
    end

    def pipelines
      @pipelines ||= Pipelines.new(self)
    end

    def config_repo_path
      @config_repo_path ||= File.join("#{reference_dataset_path}/#{config_repo_name}/#{example_type}")
    end

    def template_repo_path
      @template_repo_path ||= File.join("#{reference_dataset_path}/#{template_repo_name}/#{example_type}")
    end

    def add(*inputs)
      File.open(path, 'a') do |file|
        inputs.each { |input| file.puts input.to_s }
      end
    end

    private

    def check_params(params)
      errors = []
      required_params = %w[root_deployment_name example_type config_repo_name template_repo_name path]

      required_params.each do |param|
        errors << "missing value for param #{param}" unless params[:"#{param}"]
      end

      raise ArgumentError, "Provided options incomplete:\n" + errors.join("\n") unless errors.empty?
    end

    def reference_dataset_path
      @reference_dataset_path ||= File.join("#{PROJECT_ROOT_DIR}/docs/reference_dataset")
    end

    def write_exhibit_intro
      add "# Directory structure '#{root_deployment_name}' for '#{example_type}' example",
          ""
    end

    def cleanup_document
      File.open(path, 'w') { |file| file.write "" }
    end
  end
end
