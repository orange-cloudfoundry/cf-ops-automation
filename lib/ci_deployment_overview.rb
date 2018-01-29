require 'yaml'

class CiDeploymentOverview
  attr_reader :base_dir

  def initialize(path)
    @base_dir = path
  end



  # ci-deployment:
  #     ops-depls:
  #     target_name: concourse-ops
  #     pipelines:
  # ops-depls-generated:
  #     config_file: concourse/pipelines/ops-depls-generated.yml
  # vars_files:
  #     - master-depls/concourse-ops/pipelines/credentials-ops-depls-pipeline.yml
  # - ops-depls/ops-depls-versions.yml
  # ops-depls-cf-apps-generated:
  #     config_file: concourse/pipelines/ops-depls-cf-apps-generated.yml
  # vars_files:
  #     - master-depls/concourse-ops/pipelines/credentials-ops-depls-pipeline.yml
  # - ops-depls/ops-depls-versions.yml
  #

  def overview
    ci_deployment = {}
    puts "Path CI deployment overview: #{@base_dir}"

    Dir[@base_dir].select { |f| File.directory? f }.each do |filename|
      dirname = filename.split('/').last
      puts "Processing #{dirname}"
      Dir[filename + '/ci-deployment-overview.yml'].each do |deployment_file|
        puts "CI deployment detected: #{dirname}"
        current_deployment = YAML.load_file(deployment_file)
        raise "#{deployment_file} - Invalid deployment: expected 'ci-deployment' key as yaml root" if (current_deployment.nil? || current_deployment['ci-deployment'].nil?)
        current_deployment['ci-deployment'].each do |deployment_name, deployment_details|
          raise "#{deployment_file} - missing keys: expecting keys target and pipelines" if deployment_details.nil?
          raise "#{deployment_file} - Invalid deployment: expected <#{dirname}> - Found <#{deployment_name}>" if deployment_name != dirname
          ci_deployment[deployment_name] = deployment_details

          raise "#{deployment_file} - No target defined: expecting a target_name" if deployment_details['target_name'].nil?
          raise "#{deployment_file} - No pipeline detected: expecting at least one pipeline" if deployment_details['pipelines'].nil?

          deployment_details['pipelines'].each do |pipeline_name, pipeline_details|
            raise "#{deployment_file} - missing keys: expecting keys vars_files and config_file (optional)" if pipeline_details.nil?
            raise "#{deployment_file} - missing key: vars_files. Expecting an array of at least one concourse var file" if pipeline_details['vars_files'].nil?
            puts "Generating default value for key config_file in #{pipeline_name}" if pipeline_details['config_file'].nil?
            pipeline_details['config_file'] = "concourse/pipelines/#{pipeline_name}.yml" if pipeline_details['config_file'].nil?
          end
        end
      end
      # puts "##############################"
      #    ci_deployment.each do |aDep|
      #        puts aDep
      #    end
      # puts "##############################"
    end
    puts "ci_deployment loaded: \n#{YAML.dump(ci_deployment)}"
    ci_deployment
  end

  def self.getTeams(overview)
    overview.map{ |_,root_depls| root_depls }
        .map { |root_depls| root_depls['pipelines'] }
        .inject([]) { |array, item| array + item.to_a }
        .map { |_, pipeline_config| pipeline_config['team'] }
        .compact
        .uniq
  end


end