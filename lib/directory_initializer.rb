require 'fileutils'
require 'yaml'
require_relative '../lib/root_deployment_version'

class DirectoryInitializer
  attr_reader :root_deployment_name, :secrets_dir, :template_dir

  def initialize(root_deployment_name, secrets_dir, template_dir, terraform_dir = '')
    @root_deployment_name = root_deployment_name
    @secrets_dir = secrets_dir
    @template_dir = template_dir
    @terraform_dir = terraform_dir
    raise 'invalid root_deployment_name for directory initialiazer' unless validate_string @root_deployment_name
    raise 'invalid secrets_dir for directory initialiazer' unless validate_string @secrets_dir
    raise 'invalid template_dir for directory initialiazer' unless validate_string @template_dir
  end

  def setup_secrets!
    dirs_to_create = files_to_create = []
    dirs_to_create << "#{@secrets_dir}/shared"
    dirs_to_create << "#{@secrets_dir}/#{@root_deployment_name}/secrets"
    create_non_existing_dirs dirs_to_create

    files_to_create << "#{@secrets_dir}/#{@root_deployment_name}/secrets/meta.yml"
    files_to_create << "#{@secrets_dir}/#{@root_deployment_name}/secrets/secrets.yml"
    # files_to_create << "#{@secrets_dir}/#{@root_deployment_name}/ci-deployment-overview.yml"

    create_non_existing_files files_to_create
    generate_default_ci_deployment_overview
  end

  def setup_templates!
    dirs_to_create = files_to_create = []

    dirs_to_create << "#{@template_dir}/#{@root_deployment_name}/template"
    create_non_existing_dirs dirs_to_create

    files_to_create << "#{@template_dir}/#{@root_deployment_name}/#{@root_deployment_name}-versions.yml"
    files_to_create << "#{@template_dir}/#{@root_deployment_name}/template/deploy.sh"
    files_to_create << "#{@template_dir}/#{@root_deployment_name}/template/cloud-config-tpl.yml"
    files_to_create << "#{@template_dir}/#{@root_deployment_name}/template/runtime-config-tpl.yml"

    RootDeploymentVersion.init_file( @root_deployment_name, {}, File.join(@template_dir, @root_deployment_name))
    create_non_existing_files files_to_create
  end

  private

  def generate_default_ci_deployment_overview
    ci_deployment_overview = {}

    ci_deployment_overview['ci-deployment'] = {
      @root_deployment_name.to_s => {
        'target_name' => 'TO_BE_DEFINED',
        'pipelines' => {
          "#{@root_deployment_name}-generated" =>
            { 'vars_files' => ["#{@root_deployment_name}/#{@root_deployment_name}-versions.yml"] },
          "#{@root_deployment_name}-cf-apps-generated" =>
            { 'vars_files' => ["#{@root_deployment_name}/#{@root_deployment_name}-versions.yml"] }
        }
      }
    }

    file = File.new("#{@secrets_dir}/#{@root_deployment_name}/ci-deployment-overview.yml", 'w')
    file << YAML.dump(ci_deployment_overview)
    file.close
  end

  def create_non_existing_dirs(dirs)
    dirs.each do |dir|
      FileUtils.mkdir_p dir unless Dir.exist? dir
    end
  end

  def create_non_existing_files(files)
    files.each do |file|
      unless File.exist? file
        file_ref = File.new(file, 'w')
        file_ref.close
      end
    end
  end

  def validate_string(cred)
    !(cred.nil? || !cred.is_a?(String) || cred.empty?)
  end

end