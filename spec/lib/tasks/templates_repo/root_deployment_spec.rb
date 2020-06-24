require 'spec_helper'
require 'tempfile'
require 'fileutils'
require 'tasks'

describe Tasks::TemplatesRepo::RootDeployment do
  let(:my_root_deployment_name) { 'my-root-deployment' }
  let(:my_root_deployment_base_dir) { 'templates-repo-dir' }
  let(:root_deployment) { described_class.new(my_root_deployment_name, my_root_deployment_base_dir) }

  before do
    allow(File).to receive(:exist?).with(File.join(my_root_deployment_base_dir, my_root_deployment_name, 'root-deployment.yml')).and_return(true)
  end

  describe ".new" do
    context "when name is empty" do
      it "raises an error" do
        err_msg = "Error: missing root deployment name ('') or base_dir ('')"
        expect { described_class.new('', '') }.to raise_error(Tasks::InvalidTaskParameter, err_msg)
      end
    end

    context "when base_dir is empty" do
      it "raises an error" do
        err_msg = "Error: missing root deployment name ('x') or base_dir ('')"
        expect { described_class.new('x', '') }.to raise_error(Tasks::InvalidTaskParameter, err_msg)
      end
    end

    context "when root deployment description file is missing" do
      it "creates an instances" do
        allow(File).to receive(:exist?).and_return(false)

        expect(root_deployment).not_to be_nil
      end
    end

    context "when root deployment description file is empty" do
      it "creates an instances" do
        allow(YAML).to receive(:load_file).and_return({})

        expect(root_deployment).not_to be_nil
      end
    end
  end

  describe ".releases_github_urls" do
    let(:yaml) do
      <<~YAML
        name: #{my_root_deployment_name}
        releases:
          os-conf:
            version: 21.0.0
            sha1: 7579a96515b265c6d828924bf4f5fae115798199
          postgres:
            version: '40'
            repository: cloudfoundry/postgres-release
            base_location: https://my-private-github.com
          prometheus:
            version: 26.2.0
            repository: cloudfoundry-community/prometheus-boshrelease
            base_location: https://github.com
          routing:
            version: 0.197.0
            repository: cloudfoundry/routing-release
            base_location: https://github.com/
          shield:
            version: 8.6.3
            repository: starkandwayne/shield-boshrelease
            base_location: https://github.com/
          uaa:
            version: 74.13.0
            sha1: 2eef558edc434d240d43ae255b59b10754d4785e
            repository: cloudfoundry/uaa-release
            base_location: https://github.com/
          no_repo:
            version: 1.0
            base_location: https://github.com/
          no_base:
            version: 1.0
            repository: cloudfoundry/no-base
        stemcell:
          version: '621.55'
      YAML
    end
    let(:loaded_yaml) { YAML.safe_load(yaml) }

    before do
      allow(YAML).to receive(:load_file).and_return(loaded_yaml)
    end

    after do
    end

    context "when no defined releases" do
      let(:yaml) { "name: #{my_root_deployment_name}" }
      it "returns empty list" do
        expect(root_deployment.releases_git_urls).to be_empty
      end
    end

    context "when releases exist" do
      let(:expected_giturls) do
        { "no_base" => "https://github.com/cloudfoundry/no-base",
          "postgres" => "https://my-private-github.com/cloudfoundry/postgres-release",
          "prometheus" => "https://github.com/cloudfoundry-community/prometheus-boshrelease",
          "routing" => "https://github.com/cloudfoundry/routing-release",
          "shield" => "https://github.com/starkandwayne/shield-boshrelease",
          "uaa" => "https://github.com/cloudfoundry/uaa-release" }
      end

      it "returns git urls" do
        expect(root_deployment.releases_git_urls).to eq(expected_giturls)
      end

      it "removes uncomplete boshrelease" do
        expected_size = root_deployment.releases.size - 2 # no_repo and os-conf
        expect(root_deployment.releases_git_urls.size).to eq(expected_size)
      end
    end
  end
end
