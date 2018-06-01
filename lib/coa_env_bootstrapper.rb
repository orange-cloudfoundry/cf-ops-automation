require 'yaml'
require 'tempfile'
require 'pathname'
require 'open3'

require_relative './coa_env_bootstrapper/bosh_helper'
require_relative './coa_env_bootstrapper/git_helper'
require_relative './coa_env_bootstrapper/concourse_helper'

class CoaEnvBootstrapper
  include BoshHelper
  include GitHelper
  include ConcourseHelper

  PROJECT_ROOT_DIR = Pathname.new(File.dirname(__FILE__) + '/..').realdirpath

  def initialize(prereqs_paths)
    @tmpdir = Dir.mktmpdir
    prereqs = {}
    prereqs_paths.each do |path|
      # TODO: check the file's existence and content
      next unless YAML.load_file(path)
      prereqs = prereqs.merge(YAML.load_file(path))
    end
    @prereqs = prereqs
  end

  def execute
    # TODO: check_prereqs
    deploy_transiant_infra if step_active?("deploy_transiant_infra")
    write_env_file
    upload_stemcell if step_active?("upload_stemcell")
    upload_cloud_config if step_active?("upload_cloud_config")
    install_git_server if step_active?("install_git_server")
    push_templates_repo
    push_secrets_repo
    download_git_dependencies
    upload_pipelines
    unpause_pipelines
    trigger_jobs
  ensure
    FileUtils.remove_entry_secure @tmpdir
  end

  def deploy_transiant_infra
    bucc_prereqs = @prereqs["bucc"]
    run_cmd "bucc up --cpi #{bucc_prereqs["cpi"]} \
#{bucc_prereqs["cpi_specific_options"]} --lite --debug"
  end

  def write_env_file
    @env_file_path = File.join(@tmpdir, 'env')
    File.write(@env_file_path, env_profile)
  end

  private

  def env_profile
    bosh_creds.
      map { |key, value| "export BOSH_#{key.upcase}='#{value}'" }.
      join("\n")
  end

  def step_active?(step_key)
    @prereqs["steps"][step_key]
  end

  def generated_concourse_credentials
    {
      "bosh-target"   => bosh_creds["target"],
      "bosh-username" => bosh_creds["client"],
      "bosh-password" => bosh_creds["client_secret"],
      "bosh-ca-cert"  => bosh_creds["ca_cert"],
      "secrets-uri"        => "git://#{git_server_ip}/secrets",
      "paas-templates-uri" => "git://#{git_server_ip}/paas-templates",
      "concourse-micro-depls-target"   => concourse_creds["url"],
      "concourse-micro-depls-username" => concourse_creds["username"],
      "concourse-micro-depls-password" => concourse_creds["password"],
      "concourse-hello-world-root-depls-insecure" => concourse_creds["insecure"],
      "concourse-hello-world-root-depls-password" => concourse_creds["password"],
      "concourse-hello-world-root-depls-target"   => concourse_creds["url"],
      "concourse-hello-world-root-depls-username" => concourse_creds["username"]
    }
  end

  def concourse_creds
    creds_source = own_concourse_vars || bucc_vars
    {
      "target"   => creds_source["concourse_target"] || "bucc",
      "url"      => creds_source["concourse_url"],
      "username" => creds_source["concourse_username"],
      "password" => creds_source["concourse_password"],
      "insecure" => creds_source["concourse_insecure"] || "true"
    }
  end

  def bosh_creds
    creds_source = own_bosh_vars || bucc_vars
    {
      "environment"   => creds_source["bosh_environment"],
      "target"        => creds_source["bosh_target"],
      "client"        => creds_source["bosh_client"],
      "client_secret" => creds_source["bosh_client_secret"],
      "ca_cert"       => creds_source["bosh_ca_cert"]
    }
  end

  def bucc_vars
    @bucc_vars ||= YAML.safe_load(`bucc vars`)
  end

  def output_dir
    @output_dir ||=
      begin
        path = File.join(@tmpdir, "output_dir")
        Dir.mkdir_p path
        path
      end
  end

  def secrets_path
    File.join(PROJECT_ROOT_DIR, "docs/reference_dataset/config_repository")
  end

  def run_cmd(cmd, opts = {})
    puts "Running: #{cmd}"
    puts "with options: #{opts.inspect}"

    cmd_to_exectute = opts[:sourced] ? ". #{@env_file_path} && #{cmd}" : cmd
    stdout, stderr, status = Open3.capture3(cmd_to_exectute)

    if status.exitstatus != 0
      if opts[:ignore_error]
        puts "Command errored, but continuing:", "stderr:", stderr, "stdout:", stdout
      else
        fail "Command errored with outputs:\nstderr:\n#{stderr}\nstdout:\n#{stdout}"
      end
    else
      puts "Command ran succesfully with output:", stdout
    end
    puts ""

    stdout
  end

  def create_file_from_prereqs(filepath, prereqs_key, additional_info = {})
    file = File.new(filepath, 'w+')
    credentials_content = @prereqs[prereqs_key].merge(additional_info)
    file.write(YAML.dump(credentials_content))
    file.close
    filepath
  end

  def own_concourse_vars
    @prereqs["concourse"]
  end

  def own_bosh_vars
    @prereqs["bosh"]
  end
end
