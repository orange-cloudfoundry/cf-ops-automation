require 'fileutils'
require 'yaml'
require_relative '../lib/root_deployment_version'
require_relative '../lib/root_deployment'

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

    create_non_existing_files files_to_create
    generate_empty_map_yaml "#{@secrets_dir}/shared/secrets.yml"
    generate_empty_map_yaml "#{@secrets_dir}/shared/meta.yml"
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

  def add_deployment(deployment_name)
    dirs_to_create = []

    dirs_to_create << "#{@template_dir}/#{@root_deployment_name}/#{deployment_name}"
    dirs_to_create << "#{@secrets_dir}/#{@root_deployment_name}/#{deployment_name}"
    create_non_existing_dirs dirs_to_create
    generate_default_deployment_dependencies(deployment_name)
  end

  def enable_deployment(deployment_name)
    files_to_create = []
    files_to_create << "#{@secrets_dir}/#{@root_deployment_name}/#{deployment_name}/#{RootDeployment::ENABLE_DEPLOYMENT_FILENAME}"
    create_non_existing_files(files_to_create)
  end

  def disable_deployment(deployment_name)
    files_to_delete = []
    files_to_delete << "#{@secrets_dir}/#{@root_deployment_name}/#{deployment_name}/#{RootDeployment::ENABLE_DEPLOYMENT_FILENAME}"
    delete_existing_files(files_to_delete)
  end

  private

  def generate_default_deployment_dependencies(deployment_name)
    deployment = Deployment.default(deployment_name)
    filename = File.join(@template_dir, @root_deployment_name, deployment_name, 'deployment-dependencies.yml')
    file_content = {'deployment' => { deployment_name => deployment.details}}
    File.open(filename, 'w') {
        |file| file << YAML.dump(file_content)
    }
  end

  def generate_empty_map_yaml(filename)
    empty_map = {}

    File.new(filename, 'w') do
        |file| file << YAML.dump(empty_map)
    end

  end

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

  def delete_existing_files(files)
    files.each do |file|
      File.delete(file) if File.exist? file
    end
  end

  def validate_string(cred)
    !(cred.nil? || !cred.is_a?(String) || cred.empty?)
  end

end