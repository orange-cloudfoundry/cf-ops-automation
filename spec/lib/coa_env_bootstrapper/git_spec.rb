require 'spec_helper'
require 'yaml'
require 'coa_env_bootstrapper/bosh'
require 'coa_env_bootstrapper/git'

shared_examples_for "an initiated and pushed repo" do |repo_path, repo_name|
  it "executes a set of git commands" do
    expect(CoaCommandRunner).to receive(:new).
      with("git remote", profile: "").ordered.
      and_return(git_remote_runner)
    expect(git_remote_runner).to receive(:execute).and_return("origin")

    expect(Dir).to receive(:chdir).with(repo_path).and_yield
    commands = [
      ["git init .", {}],
      ["git config --local user.email 'coa_env_bootstrapper@example.com'", {}],
      ["git config --local user.name 'Fake User For COA Bootstrapper Pipeline'", {}],
      ["git remote remove origin", {}],
      ["git remote add origin git://1.2.3.4/#{repo_name}", {}],
      ["git add -A && git commit -m 'Commit'", fail_silently: true],
      ["git checkout master", {}],
      ["git push origin master --force", { profile: "" }]
    ]
    commands.each do |command, options|
      expect(CoaCommandRunner).
        to receive(:new).with(command, options).and_return(runner)
      expect(runner).to receive(:execute)
    end

    git.push_secrets_repo(concourse_config)
  end
end

describe CoaEnvBootstrapper::Git do
  let(:server_ip) { "1.2.3.4" }
  let(:prereqs) { {} }
  let(:bosh_ca_cert) { "ca cert" }
  let(:bosh) do
    instance_double("CoaEnvBootstrapper::Bosh",
                    git_server_ip: server_ip,
                    config: { "ca-cert" => bosh_ca_cert },
                    bosh_client: CoaBoshClient.new({}))
  end
  let(:git) { described_class.new(bosh, prereqs) }
  let(:runner) { instance_double("CoaCommandRunner") }
  let(:git_remote_runner) { instance_double("CoaCommandRunner") }

  describe '#push_secrets_repo' do
    let(:file) { instance_double("File") }
    let(:concourse_config) { {} }
    let(:credentials_auto_init_path) { described_class::CREDENTIALS_AUTO_INIT_PATH }
    let(:concourse_credentials_path) { described_class::CONCOURSE_CREDENTIALS_PATH }
    let(:bosh_ca_certs_path) { described_class::BOSH_CA_CERTS_PATH }
    let(:git_config_path) { described_class::GIT_CONFIG_PATH }
    let(:credentdials_auto_init) { git.send(:generated_concouse_credentials, concourse_config).to_yaml }
    let(:git_config) do
      {
        "cf-ops-automation-tag-filter" => "",
        "cf-ops-automation-uri" => "git://1.2.3.4/cf-ops-automation"
      }
    end

    before do
      allow(CoaCommandRunner).to receive(:new).and_return(runner)
      allow(runner).to receive(:execute).and_return("")
      allow(File).to receive(:open).and_yield(file)
      allow(file).to receive(:write)
    end

    it "writes some config files and pushes the repo" do
      git.push_secrets_repo(concourse_config)

      expect(File).to have_received(:open).with(credentials_auto_init_path, 'w').once
      expect(file).to have_received(:write).with(credentdials_auto_init).twice

      expect(File).to have_received(:open).with(concourse_credentials_path, 'w').once

      expect(File).to have_received(:open).with(bosh_ca_certs_path, 'w').once
      expect(file).to have_received(:write).with(bosh_ca_cert).once

      expect(File).to have_received(:open).with(git_config_path, 'w').once
      expect(file).to have_received(:write).with(git_config.to_yaml).once
    end

    it_behaves_like "an initiated and pushed repo",
      described_class::SECRETS_REPO_DIR, "secrets"
  end

  describe 'push_cf_ops_automation' do
    # TODO: have better values for current_branch_name, remote_name, branch_name
    before do
      allow(CoaCommandRunner).to receive(:new).and_return(runner)
      allow(runner).to receive(:execute).and_return("")
      allow(SecureRandom).to receive(:hex).and_return("random")
    end

    it "creates a random remote name for the git server ip and a random branch name and then push on master from it" do

      expect(Dir).to receive(:chdir).with(described_class::PROJECT_ROOT_DIR).and_yield
      commands = [
        ["git branch -q | grep '*' | cut -d ' ' -f2", {}],
        ["git remote add random git://1.2.3.4/cf-ops-automation", {}],
        ["git checkout -b random", {}],
        ["git push random random:master --force", { profile: "" }],
        ["git checkout ", {}],
        ["git branch", { profile: "" }],
        ["git remote", { profile: "" }]
      ]
      commands.each do |command, options|
        expect(CoaCommandRunner).
          to receive(:new).with(command, options).and_return(runner)
        expect(runner).to receive(:execute)
      end

      git.push_cf_ops_automation
    end
  end
end


