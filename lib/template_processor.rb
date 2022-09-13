require 'yaml'
require 'erb'
require 'ostruct'
require 'fileutils'
require_relative 'pipeline_helpers'
require "active_support/core_ext/object/deep_dup"

class TemplateProcessor
  attr_reader :root_deployment_name, :config, :context

  def initialize(root_deployment_name, config = { dump_output: true, output_path: '/tmp' }, context = {})
    @root_deployment_name = root_deployment_name
    @context = context
    @config = config

    raise 'invalid root_deployment_name' if @root_deployment_name.to_s.empty?
    raise 'invalid config' unless @config
  end

  def process(dir)
    processed_template = {}
    return processed_template unless dir

    Dir[dir]&.each do |filename|
      pipeline_name = cleanup_pipeline_name(filename)
      process_pipeline(filename, pipeline_name)
      processed_template[filename] = pipeline_name
    end

    processed_template
  end

  private

  def process_pipeline(filename, pipeline_name)
    puts "processing #{filename}"
    # output = erb(filename, @context)
    output = generate_pipeline_content(filename)
    pipeline = write_pipeline_content_in_file(output, pipeline_name)
    parse_pipeline_for_yaml_verification(pipeline_name, pipeline)
  end

  def generate_pipeline_content(filename)
    output = ERB.new(File.read(filename), trim_mode: '<>').
      result(load_context_into_a_binding).
      gsub(/\n\s*\n/, "\n") # removing blank lines
    puts output if config[:dump_output]
    output
    # rescue NameError => name_error
    #   raise NameError, "#{filename}: #{name_error}"
  end

  def write_pipeline_content_in_file(output, pipeline_name)
    puts "Pipeline name #{pipeline_name}"
    target_dir = File.join(config[:output_path], 'pipelines')
    FileUtils.mkdir_p target_dir unless Dir.exist?(target_dir)
    pipeline = File.new(File.join(target_dir, pipeline_name), 'w')
    pipeline << output
    pipeline.close
    pipeline
  end

  def parse_pipeline_for_yaml_verification(pipeline_name, pipeline)
    puts "Trying to parse generated Yaml: #{pipeline_name} (#{pipeline&.path})"
    YAML.load_file(pipeline, aliases: true)
    puts "> #{pipeline_name} seems a valid Yaml file"
    2.times { puts '####################################################################################' }
  rescue Psych::SyntaxError => e
    raise "invalid #{pipeline_name} file: #{e.message}"
  end

  # This method don't fail when a variable is missing in erb file.
  def erb(template, vars = {})
    ERB.new(File.read(template), trim_mode: '<>').result(OpenStruct.new(vars).instance_eval { binding })
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
    @context&.deep_dup&.each do |k, v|
      new_binding.local_variable_set k.to_sym, v
    end
    puts "Local var: #{new_binding.local_variables}"
    new_binding
  end
end
