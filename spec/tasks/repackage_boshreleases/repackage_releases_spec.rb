require 'spec_helper'
require 'tempfile'
require 'tmpdir'
require 'tasks'
require_relative '../../../concourse/tasks/repackage_boshreleases/repackage_releases'

describe RepackageReleases do
  let(:repackage_releases) { described_class.new(root_deployment, missing_s3_releases, bosh_list_releases, bosh_create_release) }
  let(:missing_s3_releases) { {} }
  let(:process_status_zero) { instance_double(Process::Status, exitstatus: 0) }
  let(:process_status_one) { instance_double(Process::Status, exitstatus: 1) }
  let(:error_filepath) { Tempfile.new }
  let(:bosh_list_releases) { instance_double(Tasks::Bosh::ListReleases) }
  let(:bosh_create_release) { instance_double(Tasks::Bosh::CreateRelease) }
  let(:root_deployment) { instance_double(Tasks::TemplatesRepo::RootDeployment) }
  let(:list_releases_response) do
    { "backup-and-restore-sdk" => { "1.17.2" => { commit_hash: "f7138d2", deployed: true, uncommitted_changes: false } },
      "bosh" => { "270.11.0" => { commit_hash: "ead4ff2", deployed: true, uncommitted_changes: false } },
      "prometheus" => { "26.1.0" => { commit_hash: "55b2ace", deployed: false, uncommitted_changes: false }, "26.2.0" => { commit_hash: "e6dc502", deployed: true, uncommitted_changes: false } },
      "routing" => { "0.195.0" => { commit_hash: "7709fe4", deployed: false, uncommitted_changes: false } },
      "shell" => { "3.2.0" => { commit_hash: "265671b5", deployed: false, uncommitted_changes: false } },
      "shield" => { "8.6.2" => { commit_hash: "1c68eea", deployed: false, uncommitted_changes: false } },
      "store" => { "0+dev.1" => { commit_hash: "a88e5e0+", deployed: false, uncommitted_changes: false }, "0+dev.2" => { commit_hash: "a88e5e0+", deployed: true, uncommitted_changes: false } },
      "uaa" => { "74.13.0" => { commit_hash: "f5a81d2", deployed: true, uncommitted_changes: false }, "74.16.0"     => { commit_hash: "05c4109", deployed: true, uncommitted_changes: false }, "74.8.0" => { commit_hash: "c0f662e", deployed: false, uncommitted_changes: false } }
    }
  end
  let(:root_deployment_git_urls_response) do
    {
      "postgres" => "https://my-private-github.com/cloudfoundry/postgres-release",
      "prometheus" => "https://github.com/cloudfoundry-community/prometheus-boshrelease",
      "routing" => "https://github.com/cloudfoundry/routing-release",
      "shield" => "https://github.com/starkandwayne/shield-boshrelease",
      "uaa" => "https://github.com/cloudfoundry/uaa-release"
    }
  end
  let(:create_release_response) do
    ' { "Tables": [
            {
                "Content": "",
                "Header": {
                    "archive": "Archive",
                    "commit_hash": "Commit Hash",
                    "name": "Name",
                    "version": "Version"
                },
                "Rows": [
                    {
                        "archive": "/data/ntp.tgz",
                        "commit_hash": "6263f00",
                        "name": "ntp",
                        "version": "4.2.8p11"
                    }
                ],
                "Notes": null
            }
        ],
        "Blocks": null,
        "Lines": [
            "Succeeded"
        ]
    }
  '
  end
  let(:defined_releases_versions) do
    {
      'postgres' => { 'version' => '1.17.2', 'repository' => 'cloudfoundry/postgres-release', 'tag_prefix' => 'v' },
      'prometheus' => { 'version' => '270.11.0', 'repository' => 'cloudfoundry-community/prometheus-boshrelease' },
      'routing' => { 'version' => '0.195.0', 'repository' => 'cloudfoundry/routing-release' },
      'shield' => { 'version' => '8.6.3', 'repository' => 'starkandwayne/shield-boshrelease', 'tag_prefix' => 'my_prefix' },
      'uaa' => { 'version' => '74.13.0', 'repository' => 'cloudfoundry/uaa-release', 'tag_prefix' => '' }
    }
  end

  before do
    allow(root_deployment).to receive(:releases_git_urls).and_return(root_deployment_git_urls_response)
    allow(root_deployment).to receive(:release_skip_branch_checkout).and_return(false)
    allow(root_deployment).to receive(:release_version) { |name| defined_releases_versions.dig(name, 'version') }
    allow(root_deployment).to receive(:release) { |name| defined_releases_versions.dig(name) }
    allow(root_deployment).to receive(:release_tag_prefix) { |name| defined_releases_versions.dig(name, 'tag_prefix') }
    allow(bosh_list_releases).to receive(:execute).and_return(list_releases_response)
    allow(bosh_create_release).to receive(:execute).and_return(create_release_response)
  end

  describe ".new" do
    context "when root_deployment is not valid" do
      let(:expected_error_message) { 'Invalid root_deployment object' }

      it "errors on nil" do
        expect { described_class.new(nil, nil,nil, nil) }.
          to raise_error(RuntimeError, expected_error_message)
      end

      it "errors on an other type" do
        expect { described_class.new({}, nil,nil, nil) }.
          to raise_error(RuntimeError, expected_error_message)
      end
    end
  end

  describe ".process" do
    subject(:run_process) { repackage_releases.process(repackaged_releases_path, base_git_clones_path, logs_path) }

    let(:repackaged_releases_path) { Dir.mktmpdir('repackaged_releases_path') }
    let(:base_git_clones_path) { Dir.mktmpdir('base_git_clones_path') }
    let(:logs_path) { Dir.mktmpdir('logs_path') }

    context "when error occurs" do
      let(:wait_thr) { instance_double(Thread, value: instance_double(Process::Status, success?: true)) }
      let(:stdout_and_stderr) { double }
      let(:wait_thr_failure) { instance_double(Thread, value: instance_double(Process::Status, success?: false)) }
      let(:stdout_and_stderr_failure) { double }

      before do
        allow(bosh_list_releases).to receive(:execute).and_return(list_releases_response)
        allow(bosh_create_release).to receive(:execute).and_return(create_release_response)

        allow(stdout_and_stderr).to receive(:gets).and_return('Cloned git repository', nil)
        allow(Open3).to receive(:popen2e).and_yield(nil, stdout_and_stderr, wait_thr)

        allow(stdout_and_stderr_failure).to receive(:gets).and_return('Error xxx. ', nil)
        allow(Open3).to receive(:popen2e).with("git clone \"https://my-private-github.com/cloudfoundry/postgres-release\" \"#{File.join(base_git_clones_path, 'postgres')}\"").and_yield(nil, stdout_and_stderr_failure, wait_thr_failure)

        allow(Open3).to receive(:capture2).and_return(["HEAD is now at 3e5c885r... My commit", instance_double(Process::Status, success?: true)])


        allow(Dir).to receive(:exist?) { |git_clone_path| git_clone_path.start_with?(base_git_clones_path) }
        allow(FileUtils).to receive(:rm_rf)

      end

      context "when fail to clone postgres" do
        it "repackages other boshreleases (ie one without errors)" do
          expect { run_process }.to raise_error(RuntimeError) do |error|
            expect(error.message).to start_with('{"postgres"=>#<CloneError: Error xxx. Failed to clone \'postgres\'')
          end

          expect(File.read(File.join(repackaged_releases_path,'boshreleases-namespaces.csv'))).to eq("prometheus-270.11.0,cloudfoundry-community\nshield-8.6.3,starkandwayne\n")
          expect(bosh_list_releases).to have_received(:execute).once.times
          expect(Open3).to have_received(:popen2e).exactly(3).times
          expect(bosh_create_release).to have_received(:execute).exactly(2).times # only for prometheus and shield, cloning failure for postgres and
        end

        it "creates an error log" do
          begin
            run_process
          rescue RuntimeError
          end
          expect(File.size?(File.join(repackaged_releases_path, 'errors.yml'))).to be > 100
        end
      end

      context "when a CLI commands fails on list releases" do
        let(:stderr) { "e" }
        let(:stdout) { "o" }
        let(:error_message) do
          <<~TEXT
            Stderr: (Tasks::Bosh::BoshCliError)
            Stdout:
            {
                "Tables": null,
                "Blocks": [
                    "Error: Action Failed get_task: Task c3c9f620-f0fd-490d-580c-0bb639e8b767 result:"
                ],
                "Lines": [
                    "Using environment '192.168.99.155' as client 'admin'",
                    "Using deployment 'k_7bd80932-4d39-4fb9-969a-2445ade2495d'",
                    "Task 9264639",
                    "\n",
                    "\n\nTask 9264639 Started  Tue Feb 25 08:07:07 UTC 2020\nTask 9264639 Finished Tue Feb 25 08:09:03 UTC 2020\nTask 9264639 Duration 00:01:56",
                    "\nTask 9264639 error\n",
                    "Deleting deployment 'k_7bd80932-4d39-4fb9-969a-2445ade2495d':\n  Expected task '9264639' to succeed but state is 'error'",
                    "Exit code 1"
                ]
            }
          TEXT
        end

        before do
          allow(bosh_list_releases).to receive(:execute).and_raise(Tasks::Bosh::BoshCliError, error_message)
        end

        it "raises an error" do
          expect { repackage_releases.process(repackaged_releases_path, base_git_clones_path, logs_path) }.
            to raise_error(RuntimeError, /"Bosh director"=>#<Tasks::Bosh::BoshCliError: Stderr: \(Tasks::Bosh::BoshCliError\).*/)
        end
      end
    end

    context "when missing s3 bosh releases" do
      let(:wait_thr) { instance_double(Thread, value: instance_double(Process::Status, success?: true)) }
      let(:stdout_and_stderr) { double }
      let(:missing_s3_releases) { { 'uaa' => { 'version' => '74.13.0' } } }


      before do
        allow(bosh_list_releases).to receive(:execute).and_return(list_releases_response)
        allow(bosh_create_release).to receive(:execute).and_return(create_release_response)

        allow(stdout_and_stderr).to receive(:gets).and_return('Cloned git repository', nil)
        allow(Open3).to receive(:popen2e).and_yield(nil, stdout_and_stderr, wait_thr)

        allow(Open3).to receive(:capture2).and_return(["HEAD is now at 3e5c885r... My commit", instance_double(Process::Status, success?: true)])

        allow(Dir).to receive(:exist?) { |git_clone_path| git_clone_path.start_with?(base_git_clones_path) }
        allow(FileUtils).to receive(:rm_rf)

      end

      it "repackages other boshreleases (ie one without errors)" do
        expect(repackage_releases.process(repackaged_releases_path, base_git_clones_path, logs_path)).to be_nil

        expect(File.read(File.join(repackaged_releases_path,'boshreleases-namespaces.csv'))).to eq("postgres-1.17.2,cloudfoundry\nprometheus-270.11.0,cloudfoundry-community\nshield-8.6.3,starkandwayne\nuaa-74.13.0,cloudfoundry\n")
        expect(bosh_list_releases).to have_received(:execute).once.times
        expect(Open3).to have_received(:popen2e).exactly(4).times
        expect(bosh_create_release).to have_received(:execute).exactly(4).times # for all deployment except shield
        expect(Open3).to have_received(:capture2).once.with("cd #{base_git_clones_path}/postgres && git checkout v1.17.2")
        expect(Open3).to have_received(:capture2).once.with("cd #{base_git_clones_path}/prometheus && git checkout 270.11.0")
        expect(Open3).to have_received(:capture2).once.with("cd #{base_git_clones_path}/shield && git checkout my_prefix8.6.3")
        expect(Open3).to have_received(:capture2).once.with("cd #{base_git_clones_path}/uaa && git checkout 74.13.0")
      end
    end
  end
end