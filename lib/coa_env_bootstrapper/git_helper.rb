class CoaEnvBootstrapper
  module GitHelper
    def push_templates_repo
      paas_templates_path = File.join(PROJECT_ROOT_DIR, "docs/reference_dataset/template_repository")
      push_to_git(paas_templates_path, "paas-templates")
      Dir.chdir paas_templates_path
      run_cmd "git branch -D pipeline-current-master" if git_branch_exists?("pipeline-current-master")
      run_cmd "git checkout -b pipeline-current-master"
      run_cmd "git push origin pipeline-current-master --force", source: true, ignore_error: true
    ensure
      Dir.chdir PROJECT_ROOT_DIR
    end

    def push_secrets_repo
      concourse_credentials_path = File.join(secrets_path, "shared", "concourse-credentials.yml")
      create_file_from_prereqs(concourse_credentials_path, "concourse_credentials", generated_concourse_credentials)
      push_to_git(secrets_path, "secrets")
      FileUtils.rm(concourse_credentials_path)
    ensure
      Dir.chdir PROJECT_ROOT_DIR
    end

    def download_git_dependencies
      Dir.chdir @tmpdir

      run_cmd "git clone git://#{git_server_ip}/paas-templates", source: true
      run_cmd "git clone git://#{git_server_ip}/secrets", source: true

      @templates_dir = File.join(@tmpdir, "paas-templates")
      @secrets_dir = File.join(@tmpdir, "secrets")
    ensure
      Dir.chdir PROJECT_ROOT_DIR
    end

    def git_server_ip
      @git_server_ip ||=
        run_cmd("bosh -d git-server is --column ips|cut -f1", sourced: true).chomp
    end

    def git_branch_exists?(branch_name)
      run_cmd("git branch", sourced: true).split("\n").
        map { |branch| branch.delete("*").strip }.include?(branch_name)
    end

    def git_remote_exists?(remote_name)
      run_cmd("git remote", sourced: true).split("\n").include?(remote_name)
    end

    def push_to_git(repo_path, repo_name)
      Dir.chdir repo_path
      run_cmd "git init ."
      run_cmd "git config --local user.email 'fake@example.com'"
      run_cmd "git config --local user.name 'Fake User For COA Bootstrapper Pipeline'"
      run_cmd "git remote remove origin" if git_remote_exists?("origin")
      run_cmd "git remote add origin git://#{git_server_ip}/#{repo_name}"
      run_cmd "git checkout master" if git_branch_exists?("master")
      run_cmd "git add -A && git commit -m 'Commit'", ignore_error: true
      run_cmd "git push origin master --force", source: true # not working with virtualbox? `bucc routes`
    end
  end
end
