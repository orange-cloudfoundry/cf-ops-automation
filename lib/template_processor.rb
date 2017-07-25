require 'yaml'
require 'erb'
require 'ostruct'
require 'fileutils'

class TemplateProcessor
  attr_reader :root_deployment_name, :config, :context

  def initialize(root_deployment_name, config = {}, context = {})
    @root_deployment_name = root_deployment_name
    @config = config
    @context = context

  end

  def process(dir)
    processed_template_count = 0

    Dir[dir].each do |filename|
      processed_template_count += 1

      puts "processing #{filename}"

      # output = ERB.new(File.read(filename), 0, '<>').result(load_context_into_a_binding)
      output = erb(filename, @context)
      puts output if config[:dump_output]

      # trick to avoid pipeline name like ops-depls-depls-generated or ops-depls--generated
      tmp_pipeline_name = filename.split('/').last.chomp('-pipeline.yml.erb').chomp('depls')
      pipeline_name = "#{@root_deployment_name}-"
      pipeline_name << "#{tmp_pipeline_name}-" if !tmp_pipeline_name.nil? && !tmp_pipeline_name.empty?
      pipeline_name << 'generated.yml'

      puts "Pipeline name #{pipeline_name}"
      target_dir = "#{config[:output_path]}/pipelines"
      FileUtils.mkdir_p target_dir unless Dir.exist?(target_dir)
      a_pipeline = File.new("#{config[:output_path]}/pipelines/#{pipeline_name}", 'w')
      a_pipeline << output
      puts "Trying to parse generated Yaml: #{pipeline_name} (#{a_pipeline&.path})"
      YAML.load_file(a_pipeline)
      puts "> #{pipeline_name} seems a valid Yaml file"
      puts '####################################################################################'
      puts '####################################################################################'
    end

    processed_template_count
  end

  private

  def erb(template, vars = {})
    ERB.new(File.read(template), 0, '<>').result(OpenStruct.new(vars).instance_eval { binding })
  end

  def load_context_into_a_binding
    new_binding = binding
    context.each do |k, v|
      new_binding.local_variable_set k.to_sym, v
    end
    puts "Local var: #{new_binding.local_variables}"
    new_binding
  end

end