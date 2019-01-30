require 'rspec'
require_relative '../../lib/pipeline_helpers'
require_relative '../../lib/config'
require_relative '../../lib/directory_initializer'

describe PipelineHelpers do
  describe '.bosh_io_hosted?' do
    subject { described_class.bosh_io_hosted?(info) }
    let(:shield_overview) do
      deps_yaml = <<~YAML
        stemcells:
        bosh-openstack-kvm-ubuntu-trusty-go_agent:
        releases:
          cf-routing-release:
            base_location: https://bosh.io/d/github.com/
            repository: cloudfoundry-incubator/cf-routing-release
            version: 0.169.0
          route-registrar-boshrelease:
            base_location: https://bosh.io/d/github.com/
            repository: cloudfoundry-community/route-registrar-boshrelease
            version: '3'
          my-boshrelease:
            base_location: https://github.com/
            repository: cloudfoundry-community/haproxy-boshrelease
            version: 8.0.12
        bosh-deployment:
          active: true
        status: enabled
      YAML
      YAML.safe_load(deps_yaml)
    end

    context 'when a bosh release is hosted on bosh.io' do
      let(:info) { shield_overview['releases']['cf-routing-release'] }
      it { is_expected.to be_truthy }
    end

    context 'when a bosh release is NOT hosted on bosh.io' do
      let(:info) {  shield_overview['releases']['my-boshrelease'] }
      it { is_expected.to be_falsey }
    end
  end

  describe '.generate_vars_files' do
    let(:templates_dir) { Dir.mktmpdir }
    let(:config_dir) { Dir.mktmpdir }
    let(:pipeline_name) { 'my-pipeline' }
    let(:root_deployment) { 'my_root_deployment' }
    let(:config_file_list) { %w[credentials-a.yml credentials-my-pipeline.yml credentials-another-pipeline.yml xxx.yml credentials-b.yml] }
    let(:expected_vars_files) do
      [
        [config_dir, 'credentials-a.yml'],
        [config_dir, 'credentials-b.yml'],
        [config_dir, 'credentials-my-pipeline.yml'],
        [templates_dir, root_deployment, "#{root_deployment}-versions.yml"]
      ].map { |paths| File.join(paths) }
    end

    it 'generates a list of vars_files for concourse pipelines' do
      DirectoryInitializer.new(root_deployment, config_dir, templates_dir).setup_templates!
      config_file_list.each { |filename| FileUtils.touch(File.join(config_dir, filename)) }

      generated_vars_files = described_class.generate_vars_files(templates_dir, config_dir, pipeline_name, root_deployment)
      expect(generated_vars_files).to eq expected_vars_files
    end
  end

  describe '.git_resource_selected_paths' do
    let(:depls) { "hello-world" }
    let(:name) { "vault" }
    let(:git_submodules) { { "hello-world" => { "vault" => "hello" } } }
    let(:config) { { "resources" => { "templates" => { "extended_scan_path" => ["extended/scan/path", "even/more/*"] } } } }
    let(:expected_paths) { ['addme', '.gitmodules', 'extended/scan/path', 'even/more/*'] }

    it "returns a string of paths separated by commas" do
      depls_selected_paths = described_class.git_resource_selected_paths(
        depls: depls,
        name: name,
        git_submodules: git_submodules,
        config: config,
        config_key: 'templates',
        defaults: ['addme'])
      expect(depls_selected_paths).to eq(expected_paths)
    end
  end

  describe '.git_resource_loaded_submodules' do
    let(:depls) { "hello-world" }
    let(:name) { "vault" }

    context "when submodules and observed paths and/or the deployment have files/paths in common" do
      let(:all_submodules) do
        {
          "shared" => {
            "submoduleA" => ["shared/submoduleA"],
            "submoduleB" => ["shared/submoduleB"]
          },
          "shared2" => { "submoduleC" => ["shared2/submoduleC"] },
          "shared3" => { "submoduleD" => ["shared3/submoduleD"]},
          "hello-world" => {
            "vault" => ["hello-world/vault"]
          }
        }
      end

      let(:observed_paths) { ["shared/submoduleA/ntp-operators.yml", "shared2"] }

      it "returns the common submodules and the " do
        loaded_submodules = described_class.git_resource_loaded_submodules(
          depls: depls,
          name: name,
          loaded_submodules: all_submodules,
          observed_paths: observed_paths
        )

        expect(loaded_submodules).to eq(["hello-world/vault", "shared/submoduleA", "shared2/submoduleC"])
      end
    end

    context "when submodules and observed paths and/or the deployment do not have files/paths in common" do
      let(:observed_paths) { ["shared4"] }
      let(:all_submodules) do
        {
          "shared" => {
            "submoduleA" => ["shared/submoduleA"],
            "submoduleB" => ["shared/submoduleB"]
          },
          "shared2" => { "submoduleC" => ["shared2/submoduleC"] },
          "shared3" => { "submoduleD" => ["shared3/submoduleD"]},
          "hello-world" => {
            "cassandra" => ["hello-world/vault"]
          }
        }
      end

      it "returns 'none'" do
        loaded_submodules = described_class.git_resource_loaded_submodules(
          depls: depls,
          name: name,
          loaded_submodules: all_submodules,
          observed_paths: observed_paths
        )
        expect(loaded_submodules).to eq("none")
      end
    end
  end
end
