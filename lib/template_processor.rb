require 'yaml'
require 'erb'
require 'ostruct'
require 'fileutils'

class TemplateProcessor
  attr_reader :root_deployment_name, :config, :context

  def initialize(root_deployment_name, config = { dump_output: true, output_path: '/tmp' }, context = {})
    @root_deployment_name = root_deployment_name
    @context = context
    @config = config

    raise 'invalid root_deployment_name' unless validate_string @root_deployment_name
    raise 'invalid config' if @config.nil?
  end

  def process(dir)
    processed_template = {}
    return processed_template if dir.nil?

    Dir[dir]&.each do |filename|

      puts "processing #{filename}"
      output = ERB.new(File.read(filename), 0, '<>').result(load_context_into_a_binding)
      # output = erb(filename, @context)
      puts output if config[:dump_output]

      pipeline_name = cleanup_pipeline_name(filename)
      puts "Pipeline name #{pipeline_name}"
      target_dir = File.join(config[:output_path], 'pipelines')
      FileUtils.mkdir_p target_dir unless Dir.exist?(target_dir)
      a_pipeline = File.new(File.join(target_dir, pipeline_name), 'w')
      a_pipeline << output
      a_pipeline.close
      processed_template[filename] = pipeline_name
      puts "Trying to parse generated Yaml: #{pipeline_name} (#{a_pipeline&.path})"
      raise "invalid #{pipeline_name} file" unless YAML.load_file(a_pipeline)
      puts "> #{pipeline_name} seems a valid Yaml file"
      puts '####################################################################################'
      puts '####################################################################################'
    end

    processed_template
  end

  private

  # This method don't fail when a variable is missing in erb file.
  def erb(template, vars = {})
    ERB.new(File.read(template), 0, '<>').result(OpenStruct.new(vars).instance_eval { binding })
  end

  def cleanup_pipeline_name(filename)
    # trick to avoid pipeline name like ops-depls-depls-generated or ops-depls--generated
    tmp_pipeline_name = filename.split('/').last.chomp('-pipeline.yml.erb').chomp('depls')
    pipeline_name = "#{@root_deployment_name}-"
    pipeline_name << "#{tmp_pipeline_name}-" if !tmp_pipeline_name.nil? && !tmp_pipeline_name.empty?
    pipeline_name << 'generated.yml'
  end

  def load_context_into_a_binding
    new_binding = binding
    context&.each do |k, v|
      new_binding.local_variable_set k.to_sym, v
    end
    puts "Local var: #{new_binding.local_variables}"
    new_binding
  end

  def validate_string(a_string)
    !(a_string.nil? || !a_string.is_a?(String) || a_string.empty?)
  end
end