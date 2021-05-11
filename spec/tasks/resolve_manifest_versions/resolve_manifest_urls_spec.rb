require 'spec_helper'
require 'tempfile'
require 'tmpdir'
require 'tasks'
require_relative '../task_spec_helper'
require_relative '../../../concourse/tasks/resolve_manifest_versions/resolve_manifest_urls'

describe ResolveManifestUrls do
  subject(:resolve_manifest_urls) { described_class.new(deployment_name, resolver, output_dir) }

  let(:deployment_name) { 'my-deployment' }
  let(:download_server_url) { 'https://releases-server.com/' }
  let(:offline_mode_enabled) { true }
  let(:stemcell_name) { 'my-stemcell' }
  let(:stemcell_version) { '0.0.7' }
  let(:stemcell_os) { 'my-os' }
  let(:resolver) { BoshIoReleaseUrlResolver.new(resolver_config) }
  let(:resolver_config) do
    {
        'DOWNLOAD_SERVER_URL' => download_server_url, # 'https://bosh.io/d/github.com/',
        'OFFLINE_MODE_ENABLED' => offline_mode_enabled,
        'PRECOMPILE_MODE_ENABLED' => true,
        'STEMCELL_NAME' => stemcell_name,
        'STEMCELL_OS' => stemcell_os,
        'STEMCELL_VERSION' => stemcell_version
    }
  end
  let(:manifest_extract) do
    yaml_content = <<~YAML
      name: #{deployment_name}
      releases:
      - name: generic-scripting
        version: "3"
      - name: bosh-dns-aliases
        version: 1.5.9
      stemcells:
      - alias: default
        os: #{stemcell_os}
        version: #{stemcell_version}
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
      expect(resolve_manifest_urls.deployment_name).to eq(deployment_name)
    end
  end

  describe ".process" do
    subject(:run_process) { resolve_manifest_urls.process(manifest_extract, versions) }

    let(:versions) do
      yaml_content = <<~YAML
        stemcell:
          version: "621.76" # Mandatory
        releases:
          generic-scripting:
            version: "3"
            repository: orange-cloudfoundry/generic-scripting-release
          bosh-dns-aliases:
            version: 1.5.9
            repository: cloudfoundry/bosh-dns-aliases-release
          os-conf:
            version: 0.2.3
            repository: cloudfoundry/os-conf-release
          prometheus:
            version: 33.3.3
            repository: cloudfoundry-community/prometheus-boshrelease
      YAML
      YAML.safe_load(yaml_content)
    end
    let(:stemcell_name) { "my-stemcell-ubuntu-bionic-go_agent" }

    context "when valid versions in online mode and manifest are provided" do
      let(:download_server_url) { 'https://bosh.io/d/github.com' }
      let(:offline_mode_enabled) { false }
      let(:expected_manifest) do
        yaml_content = <<~YAML
          name: my-deployment
          releases:
            - name: generic-scripting
              url: "https://bosh.io/d/github.com/orange-cloudfoundry/generic-scripting-release?v=3"
              version: "3"
            - name: bosh-dns-aliases
              version: "1.5.9"
              url: "https://bosh.io/d/github.com/cloudfoundry/bosh-dns-aliases-release?v=1.5.9"
          stemcells:
            - alias: default
              os: my-os
              version: "0.0.7"
          update:
            canaries: 1
            update_watch_time: 10000-600000
          variables:
            - name: cf_password
              type: password
        YAML
        YAML.safe_load(yaml_content)
      end

      it "patches boshreleases url" do
        run_process
        expect(YAML.load_file(expected_output_filename)).to eq(expected_manifest)
      end
    end

    context "when valid versions in offline mode and manifest are provided" do
      let(:resolver) { OfflineReleaseUrlResolver.new(resolver_config) }
      let(:download_server_url) { 'https://public-releases.com/my-bucket/' }
      let(:offline_mode_enabled) { true }
      let(:expected_manifest) do
        yaml_content = <<~YAML
          name: my-deployment
          releases:
            - name: generic-scripting
              url: "https://public-releases.com/my-bucket/orange-cloudfoundry/generic-scripting-3.tgz"
              version: "3"
            - name: bosh-dns-aliases
              version: "1.5.9"
              url: "https://public-releases.com/my-bucket/cloudfoundry/bosh-dns-aliases-1.5.9.tgz"
          stemcells:
            - alias: default
              os: my-os
              version: "0.0.7"
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
            os: #{stemcell_os}
            version: #{stemcell_version}
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
              os: my-os
              version: 0.0.7
          update:
            canaries: 1
            update_watch_time: 10000-600000
          variables:
            - name: cf_password
              type: password
        YAML
        YAML.safe_load(yaml_content)
      end

      it "does not patch releases urls" do
        run_process
        expect(YAML.load_file(expected_output_filename)).to eq(expected_manifest)
      end
    end

    context "when latest is used as version" do
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
            os: #{stemcell_os}
            version: #{stemcell_version}
          update:
            canaries: 1
            update_watch_time: 10000-600000
          variables:
          - name: cf_password
            type: password
        YAML
        YAML.safe_load(yaml_content)
      end

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
              os: my-os
              version: 0.0.7
          update:
            canaries: 1
            update_watch_time: 10000-600000
          variables:
            - name: cf_password
              type: password
        YAML
        YAML.safe_load(yaml_content)
      end

      it "keeps latest versions and does not patch release urls" do
        run_process
        expect(YAML.load_file(expected_output_filename)).to eq(expected_manifest)
      end
    end
  end
end