require 'yaml'

class ConcoursePipelineResourceConfigGenerator
  def initialize(base_dir = ".", config_dir = '', output_dir = '')
    @pipelines = { 'pipelines' => [] }
    @pipelines_base_dir = base_dir
    @config_dir = config_dir
    @output_dir = output_dir
    @team_name = ENV.fetch('PIPELINE_TEAM', 'main')
    @pipeline_name = ENV.fetch('PIPELINE_NAME', '')
    @pipeline_name_prefix = ENV.fetch('PIPELINE_NAME_PREFIX', '')
    @output_config_path = ENV.fetch('OUTPUT_CONFIG_PATH', '')
    @output_pipeline_path = ENV.fetch('OUTPUT_PIPELINE_PATH', '')
  end

  def execute
    validate_dir
    puts "execute"

    pipelines = list_pipelines
    puts pipelines
    pipelines.each do |pipeline_config_filename|
      puts "processing #{pipeline_config_filename}"
      vars_files = generate_vars_files(@pipeline_name)
      output_pipeline_config_filename = File.join(@output_pipeline_path, File.basename(pipeline_config_filename))
      add_pipeline("#{@pipeline_name_prefix}#{@pipeline_name}", @team_name, output_pipeline_config_filename, vars_files)
    end
    @pipelines['pipelines'] = @pipelines['pipelines'].sort_by { |pipeline| pipeline['name'] }
    write_yaml
  end

  private

  def write_yaml
    puts "pipelines:"
    puts @pipelines.to_yaml
    pipeline_config_file = File.join(@output_dir, 'pipelines-definitions.yml')
    File.open(pipeline_config_file, 'w') { |file| file.write(@pipelines.to_yaml) }
  end

  def list_pipelines
    Dir[File.join(@pipelines_base_dir, "*#{@pipeline_name}*")].select { |item| File.file?(item) }
  end

  def add_pipeline(name, team, config, vars_files)
    pipeline = {}
    pipeline['name'] = name
    pipeline['team'] = team || 'main'
    pipeline['config_file'] = config
    pipeline['vars_files'] = vars_files || []
    @pipelines['pipelines']. << pipeline
  end

  def generate_vars_files(pipeline_name)
    credential_filenames = Dir[File.join(@config_dir, 'credentials-*.yml')].reject { |file_path| filter_credentials_file(file_path) }
      .map { |file_path| File.basename(file_path) }
    vars_files = credential_filenames.map { |filename| File.join(@output_config_path, filename) }
    config_file_suffix = pipeline_name.gsub('-generated', '')
    config_file_suffix += '-pipeline' unless config_file_suffix.end_with?('-pipeline')
    current_pipeline_config_file = File.join(@config_dir, "credentials-#{config_file_suffix}.yml")
    puts "INFO - checking existence of #{current_pipeline_config_file}"
    vars_files << File.join(@output_config_path, "credentials-#{config_file_suffix}.yml") if File.exist?(current_pipeline_config_file)
    vars_files
  end

  def validate_dir
    error_message = ''
    error_message << "\nPipelines directory does not exist: #{@pipelines_base_dir}" unless File.exist?(@pipelines_base_dir)
    error_message << "\nConfig directory does not exist: #{@config_dir}" unless File.exist?(@config_dir)
    error_message << "\nOutput directory does not exist: #{@output_dir}" unless File.exist?(@output_dir)
    raise error_message unless error_message.empty?
  end

  def filter_credentials_file(file_path)
    File.basename(file_path).include?('pipeline') || File.basename(file_path).include?('generated')
  end
end

