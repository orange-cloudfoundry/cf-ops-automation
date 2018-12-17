require 'rspec'
require_relative '../../lib/pipeline_helpers'
require_relative '../../lib/config'
require_relative '../../lib/directory_initializer'

describe PipelineHelpers do
  describe '#bosh_io_hosted?' do
    let(:bosh_io_hosted?) { described_class.bosh_io_hosted?(info) }
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

      it 'returns true' do
        expect(bosh_io_hosted?).to be_truthy
      end
    end

    context 'when a bosh release is NOT hosted on bosh.io' do
      let(:info) {  shield_overview['releases']['my-boshrelease'] }

      it 'returns false' do
        expect(bosh_io_hosted?).to be_falsey
      end
    end
  end

  describe '#generate_vars_files' do
    let(:templates_dir) { Dir.mktmpdir }
    let(:config_dir) { Dir.mktmpdir }
    let(:pipeline_name) { 'my-pipeline' }
    let(:root_deployment) { 'my_root_deployment' }
    let(:setup_templates_dir) { DirectoryInitializer.new(root_deployment, config_dir, templates_dir).setup_templates! }
    let(:setup_config_dir) { config_file_list.each { |filename| FileUtils.touch(File.join(config_dir, filename)) } }
    let(:config_file_list) { %w[credentials-a.yml credentials-my-pipeline.yml credentials-another-pipeline.yml xxx.yml credentials-b.yml] }
    let(:expected_vars_files) do
      result = [File.join(config_dir, 'credentials-a.yml')]
      result << File.join(config_dir, 'credentials-b.yml')
      result << File.join(config_dir, 'credentials-my-pipeline.yml')
      result << File.join(templates_dir, root_deployment, "#{root_deployment}-versions.yml")
    end
    let(:generate_vars_files) { described_class.generate_vars_files(templates_dir, config_dir, pipeline_name, root_deployment) }

    before do
      setup_templates_dir
      setup_config_dir
    end

    it 'generates a list of vars_files for concourse pipelines' do
      expect(generate_vars_files).to eq expected_vars_files
    end
  end
end
