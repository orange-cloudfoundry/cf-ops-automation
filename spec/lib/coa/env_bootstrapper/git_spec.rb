require 'spec_helper'
require 'yaml'
require 'coa/env_bootstrapper/bosh'
require 'coa/env_bootstrapper/git'
require 'coa/utils/concourse'

shared_examples_for "an initiated and pushed repo" do |repo_path, repo_name|
  it "executes a set of git commands" do
    expect(Coa::Utils::CommandRunner).to receive(:new).
      with("git remote", profile: profile).ordered.
      and_return(runner)
    expect(runner).to receive(:execute).and_return("origin")
    expect(Dir).to receive(:chdir).with(repo_path).and_yield
    commands = [
      ["git init .", {}],
      ["git config --local user.email 'coa_env_bootstrapper@example.com'", {}],
      ["git config --local user.name 'Fake User For COA Bootstrapper Pipeline'", {}],
      ["git remote add origin git://1.2.3.4/#{repo_name}", {}],
      ["git add -A && git commit -m Extracted\\ safe\\ message:\\ origin", fail_silently: true],
      ["git checkout master", {}],
      ["git push origin master --force", { profile: profile }]
    ]
    commands.each do |command, options|
      expect(Coa::Utils::CommandRunner).
        to receive(:new).with(command, options).and_return(runner)
      expect(runner).to receive(:execute)
    end

    git.push_secrets_repo(concourse_config, pipeline_vars)
  end
end

describe Coa::EnvBootstrapper::Git do
  let(:server_ip) { "1.2.3.4" }
  let(:bosh_ca_cert) { "ca cert" }
  let(:bosh_config) do
    Coa::Utils::Bosh::Config.new(
      "bosh_ca_cert" => bosh_ca_cert,
      "bosh_client" => "c",
      "bosh_client_secret" => "cs",
      "bosh_environment" => "env",
      "bosh_target" => "target")
  end
  let(:profile) { "export BOSH_CA_CERT='ca cert'\nexport BOSH_CLIENT='c'\nexport BOSH_CLIENT_SECRET='cs'\nexport BOSH_ENVIRONMENT='env'\nexport BOSH_TARGET='target'" }
  let(:bosh) do
    instance_double("Coa::EnvBootstrapper::Bosh",
                    git_server_ip: server_ip,
                    config: bosh_config,
                    client: Coa::Utils::Bosh::Client.new(bosh_config))
  end
  let(:git) { described_class.new(bosh) }
  let(:runner) { instance_double("Coa::Utils::CommandRunner") }
  describe '#push_secrets_repo' do
    let(:file) { instance_double("File") }
    let(:concourse_config) do
      Coa::Utils::Concourse::Config.new("concourse_password" => "pw", "username" => "un", "url" => "url")
    end
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
    let(:pipeline_vars) { {} }

    before do
      allow(git.logger).to receive(:log_and_puts)
      allow(Coa::Utils::CommandRunner).to receive(:new).and_return(runner)
      allow(runner).to receive(:execute).and_return("")
      allow(File).to receive(:open).and_yield(file)
      allow(file).to receive(:write)
    end

    it "writes some config files and pushes the repo" do
      git.push_secrets_repo(concourse_config, pipeline_vars)

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
    before do
      allow(Coa::Utils::CommandRunner).to receive(:new).and_return(runner)
      allow(runner).to receive(:execute).and_return("")
      allow(SecureRandom).to receive(:hex).and_return("random")
    end

    it "creates a random remote name for the git server ip and a random branch name and then push on master from it" do
      expect(Dir).to receive(:chdir).with(described_class::PROJECT_ROOT_DIR).and_yield
      commands = [
        ["git log -1 --oneline| cut -d ' ' -f1", {}],
        ["git remote add remote-random git://1.2.3.4/cf-ops-automation", {}],
        ["git checkout -b br-random", {}],
        ["git push remote-random br-random:master --force", { profile: profile }],
        ["git checkout ", {}],
        ["git branch", { profile: profile }],
        ["git remote", { profile: profile }]
      ]
      commands.each do |command, options|
        expect(Coa::Utils::CommandRunner).
          to receive(:new).with(command, options).and_return(runner)
        expect(runner).to receive(:execute)
      end

      git.push_cf_ops_automation
    end
  end
end


