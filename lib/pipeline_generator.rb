require 'optparse'
require_relative './config'
require_relative './extended_config'
require_relative './bosh_certificates'
require_relative './deployment_factory'
require_relative './template_processor'
require_relative './git_modules'
require_relative './ci_deployment'
require_relative './secrets'
require_relative './cf_apps'
require_relative './root_deployment'
require_relative './root_deployment_version'
require_relative './root_deployment_overview_enhancer'

class PipelineGenerator
  attr_reader :options, :warnings
  attr_accessor :erb_context

  alias :ctxt :erb_context

  BOSH_CERT_LOCATIONS = {
    'on-demand-depls' => 'shared/certs/internal_paas-ca/server-ca.crt',
    'micro-depls' => 'shared/certs/internal_paas-ca/server-ca.crt',
    'master-depls' => 'shared/certs/internal_paas-ca/server-ca.crt',
    'expe-depls' => 'shared/certs/internal_paas-ca/server-ca.crt',
    'ops-depls' => 'shared/certs/internal_paas-ca/server-ca.crt'
  }
  BOSH_CERT_LOCATIONS.default = 'shared/certs/internal_paas-ca/server-ca.crt'

  DEFAULT_OPTIONS = {
    git_submodule_path: '../paas-templates',
    secrets_path: '..',
    output_path: 'bootstrap-generated',
    ops_automation: '.',
    dump_output: true,
    paas_templates_path: '../paas-templates',
    iaas_type: 'openstack',
    profiles: [],
    profiles_auto_sort: true,
    exclude_pipelines: [],
    include_pipelines: []
  }.freeze

  def initialize(options)
    @options = OpenStruct.new(options)
    @erb_context = ErbContext.new
    @warnings = []
  end

  def execute
    pipeline_templates_filter = PipelineTemplatesFiltering.new(@options)
    @options.input_pipelines = pipeline_templates_filter.filter

    load_erb_context
    process_templates
  end

  def display_warnings
    puts warnings.join("\n") + "\n"
  end

  private

  def load_erb_context
    deployment_versions_path = "#{options.paas_templates_path}/#{options.depls}/root-deployment.yml"
    raise "#{options.depls}/root-deployment.yml: file not found. #{deployment_versions_path} does not exist" unless File.exist? deployment_versions_path

    set_context
    check_warnings
  end

  def set_context
    shared_config  = File.join(options.paas_templates_path, 'shared-config.yml')
    private_config = File.join(options.secrets_path, 'private-config.yml')
    profiles = if options.profiles_auto_sort
                 options.profiles.sort
               else
                 options.profiles
               end
    extended_config = ExtendedConfigBuilder.new.with_iaas_type(options.iaas_type).with_profiles(profiles).build
    config = Config.new(shared_config, private_config, extended_config).load_config
    root_deployment_name = options.depls
    root_deployment_versions = RootDeploymentVersion.load_file("#{options.paas_templates_path}/#{root_deployment_name}/root-deployment.yml")
    deployment_factory = DeploymentFactory.new(root_deployment_name, root_deployment_versions.versions, config)

    root_deployment_overview = RootDeployment.new(root_deployment_name, options.paas_templates_path, options.secrets_path).overview_from_hash(deployment_factory)
    versions = root_deployment_versions.versions
    enhanced_root_deployment = RootDeploymentOverviewEnhancer.new(root_deployment_name, root_deployment_overview, versions).enhance

    ctxt.depls                 = root_deployment_name
    ctxt.bosh_cert             = BoshCertificates.new(options.secrets_path, BOSH_CERT_LOCATIONS).load_from_location.certs
    ctxt.secrets_dirs_overview = Secrets.new("#{options.secrets_path}/*").overview
    ctxt.version_reference     = versions
    ctxt.all_dependencies      = enhanced_root_deployment
    ctxt.all_ci_deployments    = CiDeployment.new(File.join(options.secrets_path, ctxt.depls)).overview
    ctxt.all_cf_apps           = CfApps.new(File.join(options.secrets_path, ctxt.depls, '/*'), ctxt.depls).overview
    ctxt.git_submodules        = GitModules.new(options.git_submodule_path).list
    ctxt.config                = config.loaded_config
    ctxt.ops_automation_path   = options.ops_automation
  end

  def check_warnings
    warnings << "### WARNING ### no deployment detected. Please check\n template_dir: #{options.paas_templates_path}\n secrets_dir: #{options.secrets_path}" if ctxt.all_dependencies.empty?
    warnings << '### WARNING ### no ci deployment detected. Please check a valid ci-deployment-overview.yml exists' if ctxt.all_ci_deployments.empty?
    warnings << '### WARNING ### no cf app deployment detected. Please check a valid enable-cf-app.yml exists' if ctxt.all_cf_apps.empty?
    warnings << '### WARNING ### no gitsubmodule detected' if ctxt.git_submodules.empty?
  end

  def process_templates
    processor = TemplateProcessor.new(self.ctxt.depls, options.to_h, self.ctxt.to_h)
    processed_template_count = generate_templates(processor)
    display_template_procession_messages(processed_template_count)
  end

  def generate_templates(processor)
    processed_template_count = 0
    return processed_template_count unless options.input_pipelines

    options.input_pipelines.each do |dir|
      processed_template = processor.process(dir)
      processed_template_count += processed_template.length
    end

    processed_template_count
  end

  def display_template_procession_messages(processed_template_count)
    if processed_template_count.positive?
      puts "#{processed_template_count} concourse pipeline templates were processed"
    else
      puts "ERROR: no concourse pipeline templates found in #{options.ops_automation}/concourse/pipelines/template/"
      puts 'ERROR: use -a option to set cf-ops-automation root dir <AUTOMATION_ROOT_DIR>/concourse/pipelines/template/'
      false
    end

    puts 'Thanks, Orange CloudFoundry SKC'
    true
  end

  class Parser
    class << self
      def parse(args)
        options = PipelineGenerator::DEFAULT_OPTIONS.dup

        opt_parser = option_parser(options)
        opt_parser.parse!(args)
        opt_parser.abort(opt_parser.to_s) if options[:depls].to_s.empty?

        options
      end

      def option_parser(options)
        OptionParser.new do |opts|
          opts.banner = "Incomplete/wrong parameter(s): #{opts.default_argv}.\n Usage: ./#{opts.program_name} <options>"

          opts.on('-d', '--depls ROOT_DEPLOYMENT', 'Specify a root deployment name to generate template for. MANDATORY') do |deployment_string|
            options[:depls] = deployment_string
          end

          opts.on('-t', '--templates-path PATH', 'Base location for paas-templates (implies -s)') do |tp_string|
            options[:paas_templates_path] = tp_string
            options[:git_submodule_path] = tp_string
          end

          opts.on('-s', '--git-submodule-path PATH', '.gitsubmodule path') do |gsp_string|
            options[:git_submodule_path] = gsp_string
          end

          opts.on('-p', '--secrets-path PATH', 'Base secrets dir (i.e. enable-deployment.yml, enable-cf-app.yml, etc.)') do |sp_string|
            options[:secrets_path] = sp_string
          end

          opts.on('-o', '--output-path PATH', 'Output dir for generated pipelines.') do |op_string|
            options[:output_path] = op_string
          end

          opts.on('-a', '--automation-path PATH', 'Base location for cf-ops-automation') do |ap_string|
            options[:ops_automation] = ap_string
          end

          opts.on('-i', '--input PIPELINE1,PIPELINE2', Array, 'List of pipelines to process without full path and without suffix "-pipeline.yml.erb"') do |ip_array|
            options[:input_pipelines] = ip_array
          end

          opts.on('-e', '--exclude PIPELINE1,PIPELINE2', Array, 'List of pipelines to exclude') do |ep_array|
            options[:exclude_pipelines] = ep_array
          end

          opts.on('--[no-]dump', 'Dump genereted file on standart output') do |dump|
            options[:dump_output] = dump
          end

          opts.on('--iaas IAAS_TYPE', 'Target a specific iaas for pipeline generation') do |iaas_type|
            options[:iaas_type] = iaas_type
          end

          opts.on('--profiles PROFILES', Array, 'List specific profiles to apply for pipeline generation,separated by "," (e.g. boostrap,feature-a,feature-b)') do |profiles_type|
            options[:profiles] = profiles_type
          end

          opts.on('--[no-]profiles-auto-sort', "Sort alphabetically profiles. Default: #{options[:profiles_auto_sort]}") do |auto_sort|
            options[:profiles_auto_sort] = auto_sort
          end
        end
      end
    end
  end

  class PipelineTemplatesFiltering
    attr_reader :options

    def initialize(options, location = "/concourse/pipelines/template")
      @required_pipeline_templates = options.input_pipelines || []
      @excluded_pipeline_templates = options.exclude_pipelines || []
      @templates_base_dir = File.join(options.ops_automation || '.', location)
    end

    def filter
      pipelines_to_process = filter_pipeline_templates
      raise "No pipeline templates detected. Please check your CLI options." if pipelines_to_process.empty?

      pipelines_to_process
    end

    private

    def filter_pipeline_templates
      selected_templates = if @required_pipeline_templates.empty?
                             select_all_pipeline_templates
                           else
                             select_matching_pipeline_templates(@required_pipeline_templates)
                           end

      exclude_pipeline_templates(selected_templates)
      selected_templates
    end

    def exclude_pipeline_templates(pipelines)
      @excluded_pipeline_templates.each do |excluded_pipeline|
        remove_excluded_pipeline_templates(excluded_pipeline, pipelines)
      end
    end

    def select_matching_pipeline_templates(pipelines_to_process)
      pipelines_subset = []
      pipelines_to_process.each do |template_name|
        pipelines_subset.concat(Dir["#{@templates_base_dir}/#{template_name}-pipeline.yml.erb"])
      end
      pipelines_subset
    end

    def select_all_pipeline_templates
      Dir["#{@templates_base_dir}/*.yml.erb"]
    end

    def remove_excluded_pipeline_templates(excluded_pipeline, pipelines)
      pipelines.delete_if do |pipeline_filepath|
        name = File.basename(pipeline_filepath, ".yml.erb")
        name.match(excluded_pipeline)
      end
    end
  end

  ErbContext = Struct.new(
    :depls,
    :bosh_cert,
    :secrets_dirs_overview,
    :version_reference,
    :all_dependencies,
    :all_ci_deployments,
    :all_cf_apps,
    :git_submodules,
    :config,
    :ops_automation_path
  )
end
