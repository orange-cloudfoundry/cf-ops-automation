require 'optparse'
require_relative './config'
require_relative './bosh_certificates'
require_relative './deployment_factory'
require_relative './template_processor'
require_relative './git_modules'
require_relative './ci_deployment_overview'
require_relative './secrets'
require_relative './cf_app_overview'
require_relative './root_deployment'
require_relative './root_deployment_version'


class PipelineGenerator
  attr_reader :options, :warnings

  # TODO add rspec file to avoid regression
  BOSH_CERT_LOCATIONS = {
    'on-demand-depls' => 'shared/certs/internal_paas-ca/server-ca.crt',
    'micro-depls' => 'shared/certs/internal_paas-ca/server-ca.crt',
    'master-depls' => 'shared/certs/internal_paas-ca/server-ca.crt',
    'expe-depls' => 'shared/certs/internal_paas-ca/server-ca.crt',
    'ops-depls' => 'shared/certs/internal_paas-ca/server-ca.crt'
  }
  BOSH_CERT_LOCATIONS.default = 'shared/certs/internal_paas-ca/server-ca.crt'

  # Argument parsing
  DEFAULT_OPTIONS = {
    :git_submodule_path => '../paas-templates',
    :secret_path => '..',
    :output_path => 'bootstrap-generated',
    :ops_automation => '.',
    :dump_output => true,
    :paas_template_root => '../paas-templates'
  }

  def initialize(options={})
    @options = options
    @warnings = []
  end

  def execute
    erb_context = collect_erb_context()
    return process_templates(erb_context)
  end

  def display_warnings
    puts warnings.join("\n") + "\n"
  end

  private

  def collect_erb_context
    deployments = options[:depls]
    unless File.exist? "#{options[:paas_template_root]}/#{deployments}/#{deployments}-versions.yml"
      raise "#{deployments}-versions.yml: file not found. #{options[:paas_template_root]}/#{deployments}/#{deployments}-versions.yml does not exist"
    end

    bosh_cert = BoshCertificates.new.load_from_location(options[:secret_path], BOSH_CERT_LOCATIONS)
    secrets_dirs_overview = Secrets.new("#{options[:secret_path]}/*").overview
    root_deployment_versions = RootDeploymentVersion.load_file("#{options[:paas_template_root]}/#{deployments}/#{deployments}-versions.yml")
    deployment_factory = DeploymentFactory.new(deployments.to_s, root_deployment_versions.versions)
    all_dependencies = RootDeployment.new(deployments.to_s, options[:paas_template_root].to_s, options[:secret_path].to_s).overview_from_hash(deployment_factory)
    warnings << "### WARNING ### no deployment detected. Please check \n template_dir: #{options[:paas_template_root]}\n secrets_dir: #{options[:secret_path]}" if all_dependencies.empty?
    all_ci_deployments = CiDeploymentOverview.new("#{options[:secret_path]}/#{deployments}").overview
    warnings << '### WARNING ### no ci deployment detected. Please check a valid ci-deployment-overview.yml exists' if all_ci_deployments.empty?
    all_cf_apps = CfAppOverview.new(File.join(options[:secret_path], deployments, '/*'), deployments).overview
    warnings << '### WARNING ### no cf app deployment detected. Please check a valid enable-cf-app.yml exists' if all_cf_apps.empty?
    git_submodules = GitModules.list(options[:git_submodule_path])
    warnings << '### WARNING ### no gitsubmodule detected' if git_submodules.empty?

    shared_config = File.join(options[:paas_template_root], 'shared-config.yml')
    private_shared_config = File.join(options[:secret_path], 'private-config.yml')
    loaded_config = Config.new(shared_config, private_shared_config).load
    puts "loaded config: #{loaded_config}"

    erb_context = {
      depls: deployments,
      bosh_cert: bosh_cert,
      secrets_dirs_overview: secrets_dirs_overview,
      version_reference: root_deployment_versions.versions,
      all_dependencies: all_dependencies,
      all_ci_deployments: all_ci_deployments,
      all_cf_apps: all_cf_apps,
      git_submodules: git_submodules,
      config: loaded_config
    }

    return erb_context
  end

  def process_templates(erb_context)
    processor = TemplateProcessor.new(options[:depls], options, erb_context)

    processed_template_count = 0
    options[:input_pipelines].each do |dir|
      processed_template = processor.process(dir)
      processed_template_count += processed_template.length
    end

    if processed_template_count.positive?
      puts "#{processed_template_count} concourse pipeline templates were processed"
    else
      puts "ERROR: no concourse pipeline templates found in #{options[:ops_automation]}/concourse/pipelines/template/"
      puts 'ERROR: use -a option to set cf-ops-automation root dir <AUTOMATION_ROOT_DIR>/concourse/pipelines/template/'
      return false
    end

    puts 'Thanks, Orange CloudFoundry SKC'
    return true
  end

  class Parser
    def self.parse(args)
      options = PipelineGenerator::DEFAULT_OPTIONS

      opt_parser = option_parser(options)
      opt_parser.parse!(args)
      opt_parser.abort("#{opt_parser}") if options[:depls].nil? || options[:depls].empty?

      if options[:input_pipelines].nil?
        options[:input_pipelines] = Dir["#{options[:ops_automation]}/concourse/pipelines/template/*.yml.erb"]
      end

      return options
    end

    def self.option_parser(options)
      OptionParser.new do |opts|
        opts.banner = "Incomplete/wrong parameter(s): #{opts.default_argv}.\n Usage: ./#{opts.program_name} <options>"

        opts.on('-d', "--depls ROOT_DEPLOYMENT", "Specify a root deployment name to generate template for. MANDATORY") do |deployment_string|
          options[:depls]= deployment_string
        end

        opts.on('-t', "--templates-path PATH", "Base location for paas-templates (implies -s)") do |tp_string|
          options[:paas_template_root] = tp_string
          options[:git_submodule_path] = tp_string
        end

        opts.on('-s', "--git-submodule-path PATH", ".gitsubmodule path") do |gsp_string|
          options[:git_submodule_path] = gsp_string
        end

        opts.on('-p', "--secrets-path PATH", "Base secrets dir (ie: enable-deployment.yml,enable-cf-app.yml, etc...).") do |sp_string|
          options[:secret_path] = sp_string
        end

        opts.on('-o', "--output-path PATH", 'Output dir for generated pipelines.') do |op_string|
          options[:output_path] = op_string
        end

        opts.on('-a', '--automation-path PATH', "Base location for cf-ops-automation") do |ap_string|
          options[:ops_automation] = ap_string
        end

        opts.on('-i', '--input PIPELINE1,PIPELINE2,', Array, 'List of pipelines to process') do |ip_array|
          options[:input_pipelines] = ip_array
        end

        opts.on('--[no-]dump', 'Dump genereted file on standart output') do |dump|
          options[:dump_output] = dump
        end
      end
    end
  end
end
