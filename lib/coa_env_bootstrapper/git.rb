require 'securerandom'
require_relative './errors'

module CoaEnvBootstrapper
  # This class manages interaction with a BOSH deployed Git server.
  class Git < Base
    CREDENTIALS_AUTO_INIT_PATH = "#{SECRETS_REPO_DIR}/coa/config/credentials-auto-init.yml".freeze
    GIT_CONFIG_PATH            = "#{SECRETS_REPO_DIR}/coa/config/credentials-git-config.yml".freeze
    CONCOURSE_CREDENTIALS_PATH = "#{SECRETS_REPO_DIR}/shared/concourse-credentials.yml".freeze
    BOSH_CA_CERTS_PATH         = "#{SECRETS_REPO_DIR}/shared/certs/internal_paas-ca/server-ca.crt".freeze

    attr_reader :bosh, :prereqs

    def initialize(bosh, prereqs)
      @bosh = bosh
      @prereqs = prereqs
    end

    def push_templates_repo
      init_and_push(TEMPLATES_REPO_DIR, "paas-templates")

      Dir.chdir TEMPLATES_REPO_DIR do
        bosh_sourced_cmd "git branch -D pipeline-current-master" if branch_exists?("pipeline-current-master")
        bosh_sourced_cmd "git checkout -b pipeline-current-master"
        bosh_sourced_cmd "git push origin pipeline-current-master --force"
      end
    end

    def push_secrets_repo(concourse_config)
      write_concourse_credentials(concourse_config)
      write_git_config
      write_bosh_ca_cert_file

      init_and_push(SECRETS_REPO_DIR, "secrets")
    end

    def push_cf_ops_automation
      Dir.chdir PROJECT_ROOT_DIR do
        remote_name = SecureRandom.hex
        branch_name = SecureRandom.hex
        current_branch_name = run_cmd "git branch -q | grep '*' | cut -d ' ' -f2"

        begin
          run_cmd "git remote add #{remote_name} git://#{server_ip}/cf-ops-automation"
          run_cmd "git checkout -b #{branch_name}"
          bosh_sourced_cmd "git push #{remote_name} #{branch_name}:master --force" # not working with virtualbox? `bucc routes`
        ensure
          unless current_branch_name.include?("(detached")
            run_cmd "git checkout #{current_branch_name}" # in some env, the current branch is detached
            run_cmd "git branch -D #{branch_name}" if branch_exists?(branch_name)
          end
          run_cmd "git remote remove #{remote_name}" if remote_exists?(remote_name)
        end
      end
    end

    private

    def server_ip
      bosh.git_server_ip
    end

    def branch_exists?(branch_name)
      bosh_sourced_cmd("git branch").
        split("\n").
        map { |branch| branch.delete("*").strip }.include?(branch_name)
    end

    def remote_exists?(remote_name)
      bosh_sourced_cmd("git remote").split("\n").include?(remote_name)
    end

    def init_and_push(repo_path, repo_name)
      Dir.chdir repo_path do
        run_cmd "git init ."
        run_cmd "git config --local user.email 'coa_env_bootstrapper@example.com'"
        run_cmd "git config --local user.name 'Fake User For COA Bootstrapper Pipeline'"
        run_cmd "git remote remove origin" if remote_exists?("origin")
        run_cmd "git remote add origin git://#{server_ip}/#{repo_name}"
        run_cmd "git add -A && git commit -m 'Commit'", fail_silently: true
        run_cmd "git checkout master"
        bosh_sourced_cmd "git push origin master --force" # not working with virtualbox? `bucc routes`
      end
    end

    # this method merges vars given in the prereqs with ones provided by env
    # that might depend on Concourse or BOSH
    def write_concourse_credentials(concourse_config)
      [CREDENTIALS_AUTO_INIT_PATH, CONCOURSE_CREDENTIALS_PATH].each do |path|
        File.open(path, 'w') do |file|
          generated_creds = generated_concouse_credentials(concourse_config)
          crendentials_auto_init = generated_creds.merge(prereqs["pipeline-vars"].to_h)
          file.write crendentials_auto_init.to_yaml
        end
      end
    end

    def write_bosh_ca_cert_file
      File.open(BOSH_CA_CERTS_PATH, 'w') do |file|
        file.write bosh.config["ca-cert"]
      end
    end

    def write_git_config
      pl_vars = prereqs["pipeline-vars"] || {}
      File.open(GIT_CONFIG_PATH, 'w') do |file|
        git_config = {
          "cf-ops-automation-tag-filter" => pl_vars["cf-ops-automation-tag-filter"].to_s,
          "cf-ops-automation-uri"        => "git://#{server_ip}/cf-ops-automation"
        }
        file.write git_config.to_yaml
      end
    end

    def bosh_sourced_cmd(cmd)
      bosh.bosh_client.run_cmd(cmd)
    end

    def generated_concouse_credentials(concourse_config)
      bosh_config = bosh.config
      {
        "concourse-micro-depls-password" => concourse_config['password'],
        "concourse-micro-depls-username" => concourse_config['username'],
        "concourse-micro-depls-target"   => concourse_config['url'],
        "concourse-hello-world-root-depls-username" => concourse_config['username'],
        "concourse-hello-world-root-depls-password" => concourse_config["password"],
        "concourse-hello-world-root-depls-insecure" => concourse_config["insecure"].to_s,
        "concourse-hello-world-root-depls-target"   => concourse_config["url"],
        "cf-ops-automation-uri" => "git://#{server_ip}/cf-ops-automation",
        "paas-templates-uri"    => "git://#{server_ip}/paas-templates",
        "secrets-uri"           => "git://#{server_ip}/secrets",
        "bosh-username" => bosh_config["client"],
        "bosh-password" => bosh_config["client-secret"],
        "bosh-target"   => bosh_config["environment"]
      }
    end
  end
end
