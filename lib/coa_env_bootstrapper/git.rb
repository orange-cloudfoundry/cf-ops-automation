module CoaEnvBootstrapper
  class Git
    attr_reader :ceb

    def initialize(coa_env_bootstrapper)
      @ceb = coa_env_bootstrapper
    end

    def prepare_environment
      # TODO: check if git ip is present
      push_templates_repo
      push_secrets_repo
      download_git_dependencies
    end

    def push_templates_repo
      paas_templates_path = File.join(PROJECT_ROOT_DIR, "docs/reference_dataset/template_repository")

      init_and_push(paas_templates_path, "paas-templates")
      Dir.chdir paas_templates_path
      run_cmd "git branch -D pipeline-current-master" if git_branch_exists?("pipeline-current-master")
      run_cmd "git checkout -b pipeline-current-master"
      run_cmd "git push origin pipeline-current-master --force", source: true, ignore_error: true
    end

    def push_secrets_repo
      repo_path = File.join(PROJECT_ROOT_DIR, "docs/reference_dataset/config_repository")
      concourse_credentials_path = File.join(repo_path, "shared", "concourse-credentials.yml")

      create_file_from_prereqs(concourse_credentials_path, "concourse_credentials", generated_concourse_credentials)
      init_and_push(repo_path, "secrets")
      FileUtils.rm(concourse_credentials_path)
    end

    def download_git_dependencies
      Dir.chdir ceb.tmpdir

      run_cmd "git clone git://#{server_ip}/paas-templates", source: true
      run_cmd "git clone git://#{server_ip}/secrets", source: true
    end

    def server_ip
      @server_ip ||=
        run_cmd("bosh -d git-server is --column ips|cut -f1", sourced: true).chomp
    end

    private

    def branch_exists?(branch_name)
      run_cmd("git branch", sourced: true).split("\n").
        map { |branch| branch.delete("*").strip }.include?(branch_name)
    end

    def remote_exists?(remote_name)
      run_cmd("git remote", sourced: true).split("\n").include?(remote_name)
    end

    def init_and_push(repo_path, repo_name)
      # TODO: check if repo exists
      Dir.chdir repo_path
      run_cmd "git init ."
      run_cmd "git config --local user.email 'fake@example.com'"
      run_cmd "git config --local user.name 'Fake User For COA Bootstrapper Pipeline'"
      run_cmd "git remote remove origin" if remote_exists?("origin")
      run_cmd "git remote add origin git://#{server_ip}/#{repo_name}"
      run_cmd "git checkout master" if branch_exists?("master")
      run_cmd "git add -A && git commit -m 'Commit'", ignore_error: true
      run_cmd "git push origin master --force", source: true # not working with virtualbox? `bucc routes`
    end
  end
end
