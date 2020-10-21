require 'spec_helper'
require 'tempfile'
require 'tmpdir'
require 'tasks'
require_relative '../task_spec_helper'
require_relative '../../../concourse/tasks/repackage_boshreleases_fallback/repackage_releases_fallback'

describe RepackageReleasesFallback do
  subject(:repackage_releases_fallback) { described_class.new(errors_filepath) }

  let(:basedir) { File.dirname(__FILE__) }
  let(:errors_filepath) { File.join(repackaged_releases_path, "errors.yml") }
  let(:process_status_zero) { instance_double(Process::Status, exitstatus: 0) }
  let(:process_status_one) { instance_double(Process::Status, exitstatus: 1) }
  let(:bosh_list_releases) { instance_double(Tasks::Bosh::ListReleases) }
  let(:bosh_create_release) { instance_double(Tasks::Bosh::CreateRelease) }
  let(:root_deployment) { instance_double(Tasks::TemplatesRepo::RootDeployment) }


  describe ".new" do

    context "when errors file does not exist" do
      let(:repackaged_releases_path) { File.join(basedir, 'dummy_dir') }

      it "creates an object without errors" do
        expect(repackage_releases_fallback.has_errors?).to be_falsey
      end
    end

    context "when errors file is empty" do
      let(:repackaged_releases_path) { File.join(basedir, 'dummy_dir') }

      before do
        allow(YAML).to receive(:load_file).and_return({})
      end

      it "creates an object without errors" do
        expect(repackage_releases_fallback.has_errors?).to be_falsey
      end
    end

    context "when errors file contains errors" do
      let(:repackaged_releases_path) { File.join(basedir, 'download_failures') }

      it "creates an object with errors" do
        expect(repackage_releases_fallback.has_errors?).to be_truthy
      end
    end
  end

  describe ".process" do
    subject(:run_process) { repackage_releases_fallback.process(repackaged_releases_fallback_path, repackaged_releases_path) }

    let(:repackaged_releases_fallback_path) { Dir.mktmpdir('repackaged_releases_fallback_path') }
    let(:repackaged_fallback_files) { Dir.chdir(repackaged_releases_fallback_path) { Dir['*'] }.sort }

    context "when an error occurs during download" do
      let(:repackaged_releases_path) { File.join(basedir, 'download_failures') }

      before do
        allow(URI).to receive(:open).with('https://bosh.io/d/github.com/cloudfoundry/os-conf-release?v=21.0.0', 'rb').and_raise(Net::ReadTimeout)
        allow(URI).to receive(:open).with('https://github.com/cloudfoundry/os-conf-release/releases/download/v21.0.0/os-conf-21.0.0.tgz', 'rb').and_raise(Net::ReadTimeout)
      end

      it "retries before failling" do
        expect {run_process}.to raise_error(RuntimeError)

        expect(URI).to have_received(:open).exactly(3).times.with('https://bosh.io/d/github.com/cloudfoundry/os-conf-release?v=21.0.0', 'rb')
        expect(URI).to have_received(:open).exactly(3).times.with('https://github.com/cloudfoundry/os-conf-release/releases/download/v21.0.0/os-conf-21.0.0.tgz', 'rb')
        expect(URI).to have_received(:open).exactly(6).times
      end

    end

    context "when fallback to bosh.io" do
      let(:repackaged_releases_path) { File.join(basedir, 'multiple_downloads') }
      let(:expected_repackaged_fallback_files) { %w[fallback-fixes.yml os-conf-21.0.0.tgz minio-2020-06-18T02-23-35Z.tgz boshreleases-namespaces.csv].sort }

      before do
        allow(URI).to receive(:open).with('https://bosh.io/d/github.com/minio/minio-boshrelease?v=2020-06-18T02-23-35Z', 'rb').and_return(true)
        allow(URI).to receive(:open).with('https://bosh.io/d/github.com/cloudfoundry/os-conf-release?v=21.0.0', 'rb').and_return(true)
      end

      it 'download only from bosh.io' do
        run_process
        expect(repackaged_fallback_files).to match(expected_repackaged_fallback_files)
        expect(URI).to have_received(:open).twice
      end
    end

    context "when fallback to github releases" do
      let(:repackaged_releases_path) { File.join(basedir, 'multiple_downloads') }
      let(:expected_repackaged_fallback_files) { %w[fallback-fixes.yml os-conf-21.0.0.tgz minio-2020-06-18T02-23-35Z.tgz boshreleases-namespaces.csv].sort }

      before do
        allow(URI).to receive(:open).and_raise(OpenURI::HTTPError.new(Net::HTTPServerError, StringIO.new))
        allow(URI).to receive(:open).with(/https:\/\/github.com/, 'rb').and_return(true)
      end

      it 'download only from github' do
        run_process
        expect(repackaged_fallback_files).to match(expected_repackaged_fallback_files)
        expect(URI).to have_received(:open).exactly(4).times
        expect(URI).to have_received(:open).twice.with(/https:\/\/bosh.io/, 'rb')
        expect(URI).to have_received(:open).once.with('https://github.com/minio/minio-boshrelease/releases/download/RELEASE_2020-06-18T02-23-35Z/minio-2020-06-18T02-23-35Z.tgz', 'rb')
        expect(URI).to have_received(:open).once.with('https://github.com/cloudfoundry/os-conf-release/releases/download/v21.0.0/os-conf-21.0.0.tgz', 'rb')
      end
    end

    context "when fallback to github releases with custom name" do
      let(:repackaged_releases_path) { File.join(basedir, 'override_github_release_name') }
      let(:expected_repackaged_fallback_files) { %w[fallback-fixes.yml os-conf-21.0.0.tgz minio-2020-06-18T02-23-35Z.tgz syslog-1.0.0.tgz boshreleases-namespaces.csv].sort }

      before do
        allow(URI).to receive(:open).and_raise(OpenURI::HTTPError.new(Net::HTTPServerError, StringIO.new))
        allow(URI).to receive(:open).with(/https:\/\/github.com/, 'rb').and_return(true)
      end

      it 'download only from github' do
        run_process
        expect(repackaged_fallback_files).to match(expected_repackaged_fallback_files)
        expect(URI).to have_received(:open).exactly(6).times
        expect(URI).to have_received(:open).exactly(3).times.with(/https:\/\/bosh.io/, 'rb')
        expect(URI).to have_received(:open).once.with('https://github.com/minio/minio-boshrelease/releases/download/RELEASE_2020-06-18T02-23-35Z/minio.tgz', 'rb')
        expect(URI).to have_received(:open).once.with('https://github.com/cloudfoundry/os-conf-release/releases/download/v21.0.0/my-os-conf-release', 'rb')
        expect(URI).to have_received(:open).once.with('https://github.com/cloudfoundry/syslog/releases/download/v1.0.0/syslog-1.0.0.tgz', 'rb')
      end
    end

    context "when repackage-releases does not have errors" do
      let(:expected_files) { %w[boshreleases-namespaces.csv dummy-nats-33.tgz].sort }
      let(:repackaged_releases_path) { File.join(basedir, 'existing_files_selective_copy') }

      it "copies only tgz files and required csv file" do
        run_process
        expect(repackaged_fallback_files).to match(expected_files)
      end
    end
  end
end
