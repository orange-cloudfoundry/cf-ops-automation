require 'spec_helper'
require 'tempfile'
require 'fileutils'
require 'tasks'

describe Tasks::ConfigRepo::Deployments do
  let(:deployments) { described_class.new(my_config_repo_name) }
  let(:error_filepath) { Tempfile.new }
  let(:my_config_repo_name) { 'my-config-repo' }
  let(:my_root_deployment) { 'my-root-deployment' }
  let(:protected) { %w[depl-protected-1 depl-protected-2 depl-protected-3] }
  let(:protected_paths) { protected.map { |name| File.join('xx', my_root_deployment, name, 'protect-deployment.yml') } }
  let(:expected_deployments_result) { %w[depl-a depl-b depl-c depl-protected-1] }
  let(:expected_paths) { expected_deployments_result.map { |name| File.join('xx', my_root_deployment, name, 'enable-deployment.yml') } }
  let(:deployed) { %w[depl-delete-1 depl-delete-2 depl-delete-3] + expected_deployments_result }

  before do
    allow(ENV).to receive(:fetch).with('ROOT_DEPLOYMENT_NAME', anything).and_return(my_root_deployment)
  end

  describe ".new" do
    context "when the environment is not complete" do

      it "raises an error" do
        allow(ENV).to receive(:fetch).and_return("")

        err_msg = "missing environment variable: ROOT_DEPLOYMENT_NAME"
        expect { described_class.new }.to raise_error(Tasks::Bosh::EnvVarMissing, err_msg)
      end
    end
  end

  describe ".disabled_deployments" do
    let(:my_config_repo_name) { Dir.mktmpdir }
    let(:root_deployment_children) { %w[secrets terraform-config] + protected_depl + enabled_depls + disabled_depls }
    let(:protected_depl) { %w[protected-1]}
    let(:disabled_depls) { %w[deleted-1 deleted-2] }
    let(:enabled_depls) { %w[depl-b depl-a] }

    before do
      root_deployment_children.each do |name|
        path = File.join(my_config_repo_name, my_root_deployment, name)
        FileUtils.mkdir_p(path)
        FileUtils.touch(File.join(path, 'enable-deployment.yml')) if enabled_depls.include?(name)
        FileUtils.touch(File.join(path, 'protect-deployment.yml')) if protected_depl.include?(name)
        FileUtils.touch(File.join(path, name + '.yml'))
      end
    end

    after do
      FileUtils.rm_rf(my_config_repo_name)
    end

    context "when root deployment has disabled deployments" do
      it "returns only deployments" do
        expect(deployments.disabled_deployments).to match(disabled_depls)
      end
    end

    context "when no deployments exists" do
      let(:protected_depl) { [] }
      let(:disabled_depls) { [] }
      let(:enabled_depls) { [] }

      it "returns an empty list" do
        expect(deployments.disabled_deployments).to be_empty
      end
    end
  end

  describe ".protected_deployments" do
    context "when deployments exist" do
      it "returns only deployments marked as protected" do
        allow(Dir).to receive(:[]).with(File.join(my_config_repo_name, my_root_deployment, '**', 'protect-deployment.yml')).and_return(protected_paths)

        expect(deployments.protected_deployments).to match(protected)

        expect(Dir).to have_received(:[])
     end
    end

    context "when no protected deployments" do
      it "returns an empty list" do
        allow(Dir).to receive(:[]).with(File.join(my_config_repo_name, my_root_deployment, '**', 'protect-deployment.yml')).and_return([])

        expect(deployments.protected_deployments).to be_empty

        expect(Dir).to have_received(:[])
      end
    end
  end

  describe ".enabled_deployments" do

    before do
      #allow(Dir).to receive(:[]).with(File.join(my_config_repo_name, my_root_deployment, '**', 'enable-deployment.yml')).and_return(expected_paths)
      #allow(Dir).to receive(:exist?).and_return(true)
      #allow(Dir).to receive(:empty?).and_return(true)
      #allow(Dir).to receive(:delete)
      #allow(File).to receive(:exist?).and_return(true)
      #allow(File).to receive(:delete)
    end

    context "when deployments exist" do
      it "returns only deployments marked as enabled" do
        allow(Dir).to receive(:[]).with(File.join(my_config_repo_name, my_root_deployment, '**', 'enable-deployment.yml')).and_return(expected_paths)

        expect(deployments.enabled_deployments).to match(expected_deployments_result)

        expect(Dir).to have_received(:[])
      end
    end

    context "when no enabled deployments" do
      it "returns an empty list" do
        allow(Dir).to receive(:[]).with(File.join(my_config_repo_name, my_root_deployment, '**', 'enable-deployment.yml')).and_return([])

        expect(deployments.enabled_deployments).to be_empty

        expect(Dir).to have_received(:[])
      end
    end
  end

  describe ".deployment?" do
    let(:deployment_name) { 'my-deployment' }
    let(:deployment_dir) { File.join(my_config_repo_name, my_root_deployment, deployment_name) }

    before do
      allow(File).to receive(:exist?).and_return(false)
    end

    context "when deployment name is unexpected" do
      unexpected_dirs = %w[terraform-config secrets cf-apps-deployments]

      unexpected_dirs.each do |special_dir|
        it "is not detected '#{special_dir}' as a deployment" do
          expect(described_class.deployment?(deployment_dir, special_dir)).to be false

          expect(File).not_to have_received(:exist?)
        end
      end
    end

    context "when deployment dir only contains fingerprint file" do
      it "is not detected as a deployment" do
        expect(described_class.deployment?(deployment_dir, deployment_name)).to be false

        expect(File).not_to have_received(:exist?).with(File.join(deployment_dir, deployment_name + 'fingerprints.yml'))
      end
    end

    context "when deployment dir only contains manifest failure file" do
      it "is a deployment" do
        allow(File).to receive(:exist?).with(File.join(deployment_dir, deployment_name + '-last-deployment-failure.yml')).and_return(true)

        expect(described_class.deployment?(deployment_dir, deployment_name)).to be true

        expect(File).to have_received(:exist?).twice
      end
    end

    context "when deployment dir only contains manifest file" do
      it "is a deployment" do
        allow(File).to receive(:exist?).with(File.join(deployment_dir, deployment_name + '.yml')).and_return(true)

        expect(described_class.deployment?(deployment_dir, deployment_name)).to be true

        expect(File).to have_received(:exist?)
      end
    end

    context "when deployment dir only contains 'enable-deployment.yml'" do
      it "is a deployment" do
        allow(File).to receive(:exist?).with(File.join(deployment_dir, 'enable-deployment.yml')).and_return(true)

        expect(described_class.deployment?(deployment_dir, deployment_name)).to be true

        expect(File).to have_received(:exist?).at_least(2)
      end
    end

  end

  describe ".bosh_deployments" do
    let(:my_config_repo_name) { Dir.mktmpdir }

    before do
      FileUtils.mkdir_p(File.join(my_config_repo_name, my_root_deployment))
    end

    after do
      FileUtils.rm_rf(my_config_repo_name)
    end

    context "when listing deployments in a root deployment" do
      let(:root_deployment_children) { %w[depls-b terraform-config depls-a] }
      let(:expected_bosh_deployments) { %w[depls-a depls-b] }

      before do
        root_deployment_children.each do |name|
          path = File.join(my_config_repo_name, my_root_deployment, name)
          FileUtils.mkdir_p(path)
          FileUtils.touch(File.join(path, name + '.yml'))
        end
      end

      it "returns only deployments" do
        expect(deployments.bosh_deployments).to match(expected_bosh_deployments)
      end
    end

    context "when no deployments exists" do
      it "returns an empty list" do
        expect(deployments.bosh_deployments).to be_empty
      end
    end
  end

  describe ".cleanup_deployment" do
    let(:deployment_name) { 'my-deployment' }
    let(:deployment_dir) { File.join(my_config_repo_name, my_root_deployment, deployment_name) }

    before do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:delete).and_return(1)
      allow(Dir).to receive(:exist?).with(deployment_dir).and_return(true)
      allow(Dir).to receive(:empty?).with(deployment_dir).and_return(true)
      allow(Dir).to receive(:delete).with(deployment_dir).and_return(0)
    end

    context "when deployment dir only contains COA files" do
      it "deletes all files" do
        expect(deployments.cleanup_deployment(deployment_name)).to be true

        expect(File).to have_received(:delete).exactly(3).times
        expect(Dir).to have_received(:delete)
      end
    end

    context "when deployment dir othersfiles" do
      it "deletes all files" do
        allow(Dir).to receive(:empty?).with(deployment_dir).and_return(false)

        expect(deployments.cleanup_deployment(deployment_name)).to be false

        expect(File).to have_received(:delete).exactly(3).times
        expect(Dir).not_to have_received(:delete)
      end
    end
  end


  describe ".cleanup_disabled_deployments" do
    let(:root_deployment_children) { %w[secrets terraform-config] + protected_depl + enabled_depls + deleted_depls }
    let(:protected_depl) { %w[protected-1]}
    let(:deleted_depls) { %w[deleted-1 deleted-2]}
    let(:enabled_depls) { %w[depl-b depl-a] }
    let(:expected_bosh_deployments) { %w[depls-a depls-b] }

    before do
      root_deployment_children.each do |name|
        path = File.join(my_config_repo_name, my_root_deployment, name)
        FileUtils.mkdir_p(path)
        FileUtils.touch(File.join(path, 'enable-deployment.yml')) if enabled_depls.include?(name)
        FileUtils.touch(File.join(path, 'protect-deployment.yml')) if protected_depl.include?(name)
        FileUtils.touch(File.join(path, name + '.yml'))
      end
    end

    after do
      FileUtils.rm_rf(my_config_repo_name)
    end

    it "returns only deployments" do
      expect(deployments.cleanup_disabled_deployments).to match(deleted_depls)
    end
  end
end
