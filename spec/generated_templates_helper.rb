class GeneratedTemplatesHelper
  attr_reader :root_dir, :root_deployment_name

  def initialize(root_dir, root_deployment_name: 'hello-world-root-depls', ignore_templates_pipelines: false)
    @root_dir = root_dir
    @template_pipeline_dir = "#{@root_dir}/concourse/pipelines/template/*.erb"
    @shared_pipeline_dir = "#{@root_dir}/concourse/pipelines/shared/*.erb"
    @root_deployment_name = root_deployment_name
    @ignore_templates_pipelines = ignore_templates_pipelines
    erb_pipelines
  end

  def erb_pipelines
    template_pipelines_dir_content = Dir[@template_pipeline_dir]
    @templates_pipelines = template_pipelines_dir_content.map { |filename| File.basename(filename) }
    shared_pipelines_dir_content = Dir[@shared_pipeline_dir]
    @shared_pipelines = shared_pipelines_dir_content.map { |filename| File.basename(filename) }
    @shared_pipelines + (@ignore_templates_pipelines ? [] : @templates_pipelines)
  end

  def generated_pipelines
    pipelines_from_shared = @shared_pipelines.map do |name|
      new_name = name.gsub('-pipeline.yml.erb', '-generated.yml')
      'shared-' + new_name
    end
    pipelines_from_shared + (@ignore_templates_pipelines ? [] : add_generated_templates_pipelines)
  end

  private

  def add_generated_templates_pipelines
    pipelines_from_templates = @templates_pipelines.map do |name|
      new_name = name.gsub('-pipeline.yml.erb', '-generated.yml')
      @root_deployment_name + '-' + new_name
    end
  end
end
