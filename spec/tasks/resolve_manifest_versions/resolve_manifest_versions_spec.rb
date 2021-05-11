require 'spec_helper'
require 'tempfile'
require 'tmpdir'
require 'tasks'
require_relative '../task_spec_helper'
require_relative '../../../concourse/tasks/resolve_manifest_versions/resolve_manifest_versions'

describe ResolveManifestVersions do
  subject(:resolve_manifest_version) { described_class.new(deployment_name, manifest_extract, output_dir) }

  let(:deployment_name) { 'my-deployment' }
  let(:manifest_extract) do
    yaml_content = <<~YAML
      name: #{deployment_name}
      releases:
      - name: generic-scripting
        version: latest
      - name: bosh-dns-aliases
        version: latest
      stemcells:
      - alias: default
        os: ubuntu-bionic
        version: latest
      update:
        canaries: 1
        update_watch_time: 10000-600000
      variables:
      - name: cf_password
        type: password
    YAML
    YAML.safe_load(yaml_content)
  end
  let(:output_dir) { Dir.mktmpdir('./result-dir') }
  let(:expected_output_filename) { File.join(output_dir, "#{deployment_name}.yml") }

  describe ".new" do
    it "creates an object without errors" do
      expect(resolve_manifest_version.deployment_name).to eq(deployment_name)
    end
  end

  describe ".process" do
    subject(:run_process) { resolve_manifest_version.process(versions, stemcell_name) }

    let(:versions) do
      yaml_content = <<~YAML
        stemcell:
          version: "621.76" # Mandatory
        releases:
          generic-scripting:
            version: "3"
          bosh-dns-aliases:
            version: 1.5.9
          os-conf:
            version: 0.2.3
          prometheus:
            version: 33.3.3
      YAML
      YAML.safe_load(yaml_content)
    end
    let(:stemcell_name) { "my-stemcell-ubuntu-bionic-go_agent" }

    context "when no stemcell version is defined" do
      let(:versions) do
        yaml_content = <<~YAML
        releases:
          generic-scripting:
            version: latest
          bosh-dns-aliases:
            version: latest
        YAML
        YAML.safe_load(yaml_content)
      end

      it "raises an error" do
        expect { run_process }.to raise_error(RuntimeError, "Missing version for stemcell my-stemcell-ubuntu-bionic-go_agent. Please fix 'root-deployment.yml' or this manifest")
      end
    end

    context "when valid versions and manifest are provided" do
      let(:expected_manifest) do
        yaml_content = <<~YAML
          name: my-deployment
          releases:
            - name: generic-scripting
              version: "3"
            - name: bosh-dns-aliases
              version: "1.5.9"
          stemcells:
            - alias: default
              os: ubuntu-bionic
              version: "621.76"
          update:
            canaries: 1
            update_watch_time: 10000-600000
          variables:
            - name: cf_password
              type: password
        YAML
        YAML.safe_load(yaml_content)
      end

      it "locks all boshreleases and stemcells" do
        run_process
        expect(YAML.load_file(expected_output_filename)).to eq(expected_manifest)
      end
    end

    context "when manifest does not use 'latest' as version" do
      let(:manifest_extract) do
        yaml_content = <<~YAML
          name: #{deployment_name}
          releases:
          - name: generic-scripting
            version: 0.1
          - name: bosh-dns-aliases
            version: 0.2
          stemcells:
          - alias: default
            os: ubuntu-bionic
            version: 0.3
          update:
            canaries: 1
            update_watch_time: 10000-600000
          variables:
          - name: cf_password
            type: password
        YAML
        YAML.safe_load(yaml_content)
      end
      let(:expected_manifest) do
        yaml_content = <<~YAML
          name: my-deployment
          releases:
            - name: generic-scripting
              version: "3"
            - name: bosh-dns-aliases
              version: "1.5.9"
          stemcells:
            - alias: default
              os: ubuntu-bionic
              version: 0.3
          update:
            canaries: 1
            update_watch_time: 10000-600000
          variables:
            - name: cf_password
              type: password
        YAML
        YAML.safe_load(yaml_content)
      end

      it "overrides boshreleases versions and keeps stemcell versions" do
        run_process
        expect(YAML.load_file(expected_output_filename)).to eq(expected_manifest)
      end
    end

    context "when version are not managed by COA" do
      let(:versions) { {} }
      let(:manifest_extract) do
        yaml_content = <<~YAML
          name: #{deployment_name}
          releases:
          - name: generic-scripting
            version: 0.1
          - name: bosh-dns-aliases
            version: 0.2
          stemcells:
          - alias: default
            os: ubuntu-bionic
            version: 0.3
          update:
            canaries: 1
            update_watch_time: 10000-600000
          variables:
          - name: cf_password
            type: password
        YAML
        YAML.safe_load(yaml_content)
      end
      let(:expected_manifest) do
        yaml_content = <<~YAML
          name: my-deployment
          releases:
            - name: generic-scripting
              version: 0.1
            - name: bosh-dns-aliases
              version: 0.2
          stemcells:
            - alias: default
              os: ubuntu-bionic
              version: 0.3
          update:
            canaries: 1
            update_watch_time: 10000-600000
          variables:
            - name: cf_password
              type: password
        YAML
        YAML.safe_load(yaml_content)
      end

      it "ignores boshreleases and stemcell versions" do
        run_process
        expect(YAML.load_file(expected_output_filename)).to eq(expected_manifest)
      end
    end

    context "when latest is used as version" do
      let(:versions) do
        yaml_content = <<~YAML
        stemcell:
          version: latest
        releases:
          generic-scripting:
            version: latest
          bosh-dns-aliases:
            version: latest
        YAML
        YAML.safe_load(yaml_content)
      end

      let(:expected_manifest) do
        yaml_content = <<~YAML
          name: my-deployment
          releases:
            - name: generic-scripting
              version: latest
            - name: bosh-dns-aliases
              version: latest
          stemcells:
            - alias: default
              os: ubuntu-bionic
              version: latest
          update:
            canaries: 1
            update_watch_time: 10000-600000
          variables:
            - name: cf_password
              type: password
        YAML
        YAML.safe_load(yaml_content)
      end

      it "keeps latest versions" do
        run_process
        expect(YAML.load_file(expected_output_filename)).to eq(expected_manifest)
      end
    end

    context "when multiple stemcells are defined in manifest" do
      let(:manifest_extract) do
        yaml_content = <<~YAML
          name: #{deployment_name}
          releases:
          - name: generic-scripting
            version: latest
          - name: bosh-dns-aliases
            version: latest
          - name: os-conf
            version: latest
          - name: prometheus
            version: latest
          stemcells:
          - alias: default
            os: ubuntu-bionic
            version: latest
          - alias: openstack-hws
            name: bosh-openstack-kvm-ubuntu-bionic-go_agent
            version: latest
          update:
            canaries: 1
            update_watch_time: 10000-600000
          variables:
          - name: cf_password
            type: password
        YAML
        YAML.safe_load(yaml_content)
      end
      let(:expected_manifest) do
        yaml_content = <<~YAML
          name: my-deployment
          releases:
            - name: generic-scripting
              version: '3'
            - name: bosh-dns-aliases
              version: 1.5.9
            - name: os-conf
              version: 0.2.3
            - name: prometheus
              version: 33.3.3
          stemcells:
            - alias: default
              os: ubuntu-bionic
              version: '621.76'
            - alias: openstack-hws
              name: bosh-openstack-kvm-ubuntu-bionic-go_agent
              version: '621.76'
          update:
            canaries: 1
            update_watch_time: 10000-600000
          variables:
            - name: cf_password
              type: password
        YAML
        YAML.safe_load(yaml_content)
      end

      it "locks all boshreleases and stemcells versions matching 'os' or without 'os' set" do
        run_process
        expect(YAML.load_file(expected_output_filename)).to eq(expected_manifest)
      end
    end

    context "when multiple stemcells with different os are defined in manifest" do
      let(:manifest_extract) do
        yaml_content = <<~YAML
          name: #{deployment_name}
          releases:
          - name: generic-scripting
            version: latest
          - name: bosh-dns-aliases
            version: latest
          stemcells:
          - alias: default
            os: ubuntu-bionic
            version: latest
          - alias: default-xenial
            os: ubuntu-xenial
            version: latest
          - alias: openstack-hws
            name: bosh-openstack-kvm-ubuntu-bionic-go_agent
            version: latest
          update:
            canaries: 1
            update_watch_time: 10000-600000
        YAML
        YAML.safe_load(yaml_content)
      end
      let(:expected_manifest) do
        yaml_content = <<~YAML
          name: my-deployment
          releases:
            - name: generic-scripting
              version: '3'
            - name: bosh-dns-aliases
              version: 1.5.9
          stemcells:
            - alias: default
              os: ubuntu-bionic
              version: '621.76'
            - alias: default-xenial
              os: ubuntu-xenial
              version: 'latest'
            - alias: openstack-hws
              name: bosh-openstack-kvm-ubuntu-bionic-go_agent
              version: '621.76'
          update:
            canaries: 1
            update_watch_time: 10000-600000
        YAML
        YAML.safe_load(yaml_content)
      end

      it "ignores stemcell that does not match defined 'os'" do
        run_process
        expect(YAML.load_file(expected_output_filename)).to eq(expected_manifest)
      end
    end
  end
end