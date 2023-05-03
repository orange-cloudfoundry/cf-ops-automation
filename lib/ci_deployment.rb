require 'yaml'
require_relative 'coa_run_logger'

class CiDeployment
  attr_reader :base_path
  attr_accessor :content

  include CoaRunLogger
  def initialize(path)
    @base_path = path
    @content = {}
  end

  # ci-deployment:
  #   ops-depls:
  #     target_name: concourse-ops
  #     pipelines:
  #       ops-depls-generated:
  #         team: my-team
  #         config_file: concourse/pipelines/ops-depls-generated.yml
  #         vars_files:
  #           - master-depls/concourse-ops/pipelines/credentials-ops-depls-pipeline.yml
  #           - ops-depls/root-deployment.yml
  #       ops-depls-cf-apps-generated:
  #         config_file: concourse/pipelines/ops-depls-cf-apps-generated.yml
  #         vars_files:
  #           - master-depls/concourse-ops/pipelines/credentials-ops-depls-pipeline.yml
  #           - ops-depls/root-deployment.yml
  # or
  # ci-deployment:
  #   ops-depls:
  #     target_name: concourse-ops
  #     pipelines:
  #       ops-depls-generated:
  #         team: my-team
  #       ops-depls-cf-apps-generated:

  def overview
    logger.info "Path CI deployment overview: #{base_path}"

    Dir[base_path].select { |file| File.directory? file }.each do |path|
      load_ci_deployment_from_dir(path)
    end

    logger.debug "ci_deployment loaded: \n#{YAML.dump(content)}"
    content
  end

  def self.teams(overview)
    return [] if overview.to_s.empty? || overview.size.zero?

    ci_deployment_details_per_root_depls = overview.map { |_, ci_deployment_details_for_root_depls| ci_deployment_details_for_root_depls }
    pipelines_per_root_depls = ci_deployment_details_per_root_depls.map { |ci_deployment_details| ci_deployment_details && ci_deployment_details['pipelines'] }
    pipelines_and_pipeline_configs_2_tuple = pipelines_per_root_depls.inject([]) { |array, item| array + item.to_a }
    defined_teams = pipelines_and_pipeline_configs_2_tuple.map { |_, pipeline_config| pipeline_config && pipeline_config['team'] }
    defined_teams.compact
      .uniq
  end

  def self.team(overview, root_deployment, pipeline_name)
    ci_root_deployment = overview[root_deployment]
    ci_pipelines = ci_root_deployment['pipelines'] unless ci_root_deployment.nil?
    ci_pipeline_found = ci_pipelines[pipeline_name] unless ci_pipelines.nil?
    ci_pipeline_found['team'] unless ci_pipeline_found.nil?
  end

  private

  def load_ci_deployment_from_dir(path)
    dir_basename = File.basename(path)
    logger.debug "Processing #{dir_basename}"

    Dir[path + '/ci-deployment-overview.yml'].each do |deployment_file|
      load_ci_deployment_from_file(deployment_file, dir_basename)
    end
  end

  def load_ci_deployment_from_file(deployment_file, dir_basename)
    logger.info "CI deployment detected in #{dir_basename}"

    deployment = YAML.load_file(deployment_file, aliases: true)
    raise "#{deployment} - Invalid deployment: expected 'ci-deployment' key as yaml root" unless deployment && deployment['ci-deployment']

    begin
      deployment['ci-deployment'].each do |root_deployment_name, root_deployment_details|
        processes_ci_deployment_data(root_deployment_name, root_deployment_details, dir_basename)
      end
    rescue RuntimeError => runtime_error
      raise "#{deployment_file}: #{runtime_error}"
    end
  end

  def processes_ci_deployment_data(root_deployment_name, root_deployment_details, dir_basename)
    raise 'missing keys: expecting keys target and pipelines' unless root_deployment_details

    raise "Invalid deployment: expected <#{dir_basename}> - Found <#{root_deployment_name}>" if root_deployment_name != dir_basename

    content[root_deployment_name] = root_deployment_details
    raise 'No target defined: expecting a target_name' unless root_deployment_details['target_name']

    raise 'No pipeline detected: expecting at least one pipeline' unless root_deployment_details['pipelines']

    processes_pipeline_definitions(root_deployment_details)
  end

  def processes_pipeline_definitions(deployment_details)
    deployment_details['pipelines'].each do |pipeline_name, pipeline_details|
      next unless pipeline_details
      unless pipeline_details_config_file?(pipeline_details)
        logger.debug "Generating default value for key config_file in #{pipeline_name}"
        pipeline_details['config_file'] = "concourse/pipelines/#{pipeline_name}.yml"
      end
    end
  end

  def pipeline_details_config_file?(pipeline_details)
    return false unless pipeline_details
    pipeline_details.key?('config_file')
  end
end
