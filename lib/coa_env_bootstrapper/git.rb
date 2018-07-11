require_relative './command_runner'
require_relative './errors'

module CoaEnvBootstrapper
  # Manage interaction with COA embedded git repository
  class Git
    include CommandRunner
    attr_reader :ceb

    def initialize(coa_env_bootstrapper)
      @ceb = coa_env_bootstrapper
    end

    def push_templates_repo
      paas_templates_path = File.join(PROJECT_ROOT_DIR, "docs/reference_dataset/template_repository")

      init_and_push(paas_templates_path, "paas-templates")
      Dir.chdir paas_templates_path
      run_cmd "git branch -D pipeline-current-master" if branch_exists?("pipeline-current-master")
      run_cmd "git checkout -b pipeline-current-master"
      run_cmd "git push origin pipeline-current-master --force", ignore_error: true, source_file_path: ceb.source_profile_path
    end

    def push_secrets_repo
      repo_path = File.join(PROJECT_ROOT_DIR, "docs/reference_dataset/config_repository")
      concourse_credentials_path = add_concourse_credentials(repo_path)
      bosh_ca_cert_path = add_bosh_ca_cert(repo_path)
      init_and_push(repo_path, "secrets")
    ensure
      FileUtils.rm(concourse_credentials_path)
      File.write(bosh_ca_cert_path, "")
    end

    def download_git_dependencies
      Dir.chdir ceb.config_dir

      run_cmd "git clone git://#{server_ip}/paas-templates", source_file_path: ceb.source_profile_path
      run_cmd "git clone git://#{server_ip}/secrets", source_file_path: ceb.source_profile_path
    rescue TypeError
      raise CoaEnvBootstrapper::ConfigDirNotFound
    end

    def server_ip
      @server_ip ||=
        run_cmd("bosh -d git-server is --column ips|cut -f1", source_file_path: ceb.source_profile_path).chomp
    end

    private

    def branch_exists?(branch_name)
      run_cmd("git branch", source_file_path: ceb.source_profile_path).
        split("\n").
        map { |branch| branch.delete("*").strip }.include?(branch_name)
    end

    def remote_exists?(remote_name)
      run_cmd("git remote", source_file_path: ceb.source_profile_path).
        split("\n").include?(remote_name)
    end

    def init_and_push(repo_path, repo_name)
      Dir.chdir repo_path
      run_cmd "git init ."
      run_cmd "git config --local user.email 'fake@example.com'"
      run_cmd "git config --local user.name 'Fake User For COA Bootstrapper Pipeline'"
      run_cmd "git remote remove origin" if remote_exists?("origin")
      run_cmd "git remote add origin git://#{server_ip}/#{repo_name}"
      run_cmd "git checkout master" if branch_exists?("master")
      run_cmd "git add -A && git commit -m 'Commit'", ignore_error: true
      run_cmd "git push origin master --force", source_file_path: ceb.source_profile_path # not working with virtualbox? `bucc routes`
    end

    def add_concourse_credentials(path)
      concourse_credentials_path = File.join(path, "shared", "concourse-credentials.yml")
      ceb.create_file_from_prereqs(concourse_credentials_path, "pipeline_credentials", ceb.generated_concourse_credentials)
      concourse_credentials_path
    end

    def add_bosh_ca_cert(path)
      bosh_ca_cert_path = File.join(path, "shared", "certs", "internal_paas-ca", "server-ca.crt")
      bosh_ca_cert = ceb.generated_concourse_credentials["bosh-ca-cert"]
      File.write(bosh_ca_cert_path, bosh_ca_cert)
      bosh_ca_cert_path
    end
  end
end
