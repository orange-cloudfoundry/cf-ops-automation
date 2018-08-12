require 'securerandom'
require_relative './errors'
require_relative '../constants'

module Coa
  module EnvBootstrapper
    # This class manages interaction with a BOSH deployed Git server.
    class Git < Base
      include Coa::Constants

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
        coa_submodule_path = "shared-files/cf-ops-automation-reference-dataset-submodule-sample"
        Dir.chdir repo_path do
          submodule_commit_reference = templates_coa_reference_dataset_submodule_sha1(coa_submodule_path, repo_path)
          run_cmd "git init ."
          run_cmd "git config --local user.email 'coa_env_bootstrapper@example.com'"
          run_cmd "git config --local user.name 'Fake User For COA Bootstrapper Pipeline'"
          run_cmd "git remote remove origin" if remote_exists?("origin")
          run_cmd "git remote add origin git://#{server_ip}/#{repo_name}"
          create_git_submodule_from_templates_repo(coa_submodule_path, repo_path, submodule_commit_reference)
          run_cmd "git add -A && git commit -m 'Commit'", fail_silently: true
          run_cmd "git checkout master"
          bosh_sourced_cmd "git push origin master --force" # not working with virtualbox? `bucc routes`
        end
      end

      def templates_coa_reference_dataset_submodule_sha1(coa_submodule_path, repo_path)
        return unless repo_path == TEMPLATES_REPO_DIR
        extract_submodule_commit_reference(coa_submodule_path)
      end

      def create_git_submodule_from_templates_repo(coa_submodule_path, repo_path, submodule_commit_reference)
        return unless repo_path == TEMPLATES_REPO_DIR
        run_cmd "rm -rf #{coa_submodule_path}"
        run_cmd "git submodule add -f https://github.com/orange-cloudfoundry/cf-ops-automation-reference-dataset-submodule-sample.git #{coa_submodule_path}"
        Dir.chdir coa_submodule_path do
          run_cmd "git checkout #{submodule_commit_reference}"
        end
      end

      def extract_submodule_commit_reference(coa_submodule_path)
        git_submodule_status_result = run_cmd "git submodule status"
        git_submodule_status_result.each_line do |line|
          commit_sha1, submodule_path, = line.split(' ')
          return commit_sha1 if submodule_path.include?(coa_submodule_path)
        end
      end

      # This method merges vars given in the prereqs with ones provided by env
      # that might depend on Concourse or BOSH.
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
          file.write bosh.config.ca_cert
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
        bosh.client.run_cmd(cmd)
      end

      def generated_concouse_credentials(concourse_config)
        bosh_config   = bosh.config
        concourse_pw  = concourse_config.password
        concourse_un  = concourse_config.username
        concourse_url = concourse_config.url

        {
          "concourse-micro-depls-password"            => concourse_pw,
          "concourse-micro-depls-username"            => concourse_un,
          "concourse-micro-depls-target"              => concourse_url,
          "concourse-hello-world-root-depls-username" => concourse_un,
          "concourse-hello-world-root-depls-password" => concourse_pw,
          "concourse-hello-world-root-depls-insecure" => concourse_config.insecure,
          "concourse-hello-world-root-depls-target"   => concourse_url,
          "bosh-username"                             => bosh_config.client,
          "bosh-password"                             => bosh_config.client_secret,
          "bosh-target"                               => bosh_config.environment,
          "cf-ops-automation-uri"                     => "git://#{server_ip}/cf-ops-automation",
          "paas-templates-uri"                        => "git://#{server_ip}/paas-templates",
          "secrets-uri"                               => "git://#{server_ip}/secrets"
        }
      end
    end
  end
end
