require 'spec_helper'
require 'pipeline_generator'

describe PipelineGenerator do
  describe "#initialize" do
    context "when options are passed" do
      let(:options) { { options: "are present" } }
      let(:pipeline_generator) { described_class.new(options) }

      it "sets the received options" do
        expect(pipeline_generator.options).to eq(OpenStruct.new(options))
      end
    end
  end

  describe "#execute" do
    let(:depls) { "rspec_test_root_depl" }
    let(:paas_templates_path) { "paas_templates_path" }
    let(:secrets_path) { "secret/path" }
    let(:input_pipelines) { [] }
    let(:git_submodule_path) { "git_submodule_path" }
    let(:rspec_iaas_type) { "rspec-iaas-type" }
    let(:options) do
      {
        paas_templates_path: paas_templates_path,
        depls: depls,
        secrets_path: secrets_path,
        input_pipelines: input_pipelines,
        iaas_type: rspec_iaas_type,
        git_submodule_path: git_submodule_path
      }
    end

    let(:bosh_cert) { { "simple-depls" => "cert" } }
    let(:secrets_dirs_overview) { { "root" => "leaf" } }
    let(:root_deployment_versions) do
      versions = {
        "deployment-name" => "rspec_hello_world",
        "stemcell-version" => "rspec_stemcell_version",
        "stemcell-name" => "rspec_stemcell_name"
      }
      RootDeploymentVersion.new("rspec_hello_world", versions)
    end
    let(:shared_config) { File.join(paas_templates_path, 'shared-config.yml') }
    let(:private_config) { File.join(secrets_path, 'private-config.yml') }
    let(:extended_config) { ExtendedConfigBuilder.new.with_iaas_type(rspec_iaas_type).build }
    let(:config) { Config.new(shared_config, private_config, extended_config) }
    let(:deployment_factory) do
      DeploymentFactory.new(depls, root_deployment_versions.versions, config)
    end
    let(:all_dependencies) { {} }
    let(:all_ci_deployments) { [] }
    let(:all_cf_apps) { [] }
    let(:git_submodules) { {} }
    let(:loaded_config) { { "key" => "value" } }
    let(:bosh_certificates) { BoshCertificates.new(secrets_path, PipelineGenerator::BOSH_CERT_LOCATIONS) }
    let(:git_modules) { GitModules.new(git_submodule_path) }

    let(:erb_context) do
      {
        depls: depls,
        bosh_cert: bosh_cert,
        secrets_dirs_overview: secrets_dirs_overview,
        version_reference: root_deployment_versions.versions,
        all_dependencies: all_dependencies,
        all_ci_deployments: all_ci_deployments,
        all_cf_apps: all_cf_apps,
        git_submodules: git_submodules,
        config: loaded_config
      }
    end
    let(:template_processor) { TemplateProcessor.new(depls, options, erb_context) }
    let(:pipeline_generator) { described_class.new(options) }

    it "collects properties, pass them onto a template processor and return the result" do
      expect(File).to receive(:exist?).
        with("#{paas_templates_path}/#{depls}/#{depls}-versions.yml").
        and_return(true)

      expect(BoshCertificates).to receive(:new).
        with(secrets_path, PipelineGenerator::BOSH_CERT_LOCATIONS).
        and_return(bosh_certificates)
      expect(bosh_certificates).to receive(:load_from_location).
        and_return(bosh_certificates)
      expect(bosh_certificates).to receive(:certs).
        and_return(bosh_cert)

      expect_any_instance_of(Secrets).to receive(:overview).
        and_return(secrets_dirs_overview)

      expect(RootDeploymentVersion).to receive(:load_file).
        with("#{paas_templates_path}/#{depls}/#{depls}-versions.yml").
        and_return(root_deployment_versions)

      expect(Config).to receive(:new).with(shared_config, private_config, extended_config).
        and_return(config)
      expect(config).to receive(:load_config).
        and_return(config)
      expect(config).to receive(:loaded_config).
        and_return(loaded_config)

      expect(DeploymentFactory).to receive(:new).
        with(depls, root_deployment_versions.versions, config).
        and_return(deployment_factory)

      expect_any_instance_of(RootDeployment).to receive(:overview_from_hash).
        with(deployment_factory).
        and_return(all_dependencies)

      expect_any_instance_of(CiDeployment).to receive(:overview).
        and_return(all_ci_deployments)

      expect_any_instance_of(CfApps).to receive(:overview).
        and_return(all_cf_apps)

      expect(GitModules).to receive(:new).with(git_submodule_path).
        and_return(git_modules)
      expect(git_modules).to receive(:list).
        and_return(git_submodules)
      expect(TemplateProcessor).to receive(:new).
        #   with(depls, options, erb_context).
        and_return(template_processor)

      expect(template_processor).to receive(:process).
        at_least(:once).
        # with(input_pipelines).
        and_return("key" => "value")

      expect(pipeline_generator.execute).to be_truthy
    end
  end

  describe "#display_warnings" do
    let(:pipeline_generator) { described_class.new({}) }
    let(:warning1) { "warning1" }
    let(:warning2) { "warning2" }

    it "displays the warnings it contains" do
      pipeline_generator.warnings << warning1
      pipeline_generator.warnings << warning2

      expect { pipeline_generator.display_warnings }.
        to output("#{warning1}\n#{warning2}\n").to_stdout
    end
  end
end

describe PipelineGenerator::PipelineTemplatesFiltering do
  subject { described_class.new(options) }

  let(:options) { OpenStruct.new(ops_automation: '.', input_pipelines: nil, exclude_pipelines: []) }
  let(:pipeline_generator) { described_class.new(options) }
  let(:expected_all_pipelines_templates) do
    coa_current_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    Dir[File.join(coa_current_path, 'concourse', 'pipelines', 'template', '*.yml.erb')].map { |path| path.gsub(coa_current_path, '.') }
  end

  context "when no filter is active" do
    let(:all_pipelines_templates) { subject.filter }

    it 'does not filter any templates' do
      expect(all_pipelines_templates).to match_array(expected_all_pipelines_templates)
    end
  end

  context "when include filter is set" do
    let(:options) { OpenStruct.new(ops_automation: '.', input_pipelines: %w[bosh update dummy], exclude_pipelines: []) }
    let(:include_templates) { subject.filter }
    let(:expected_include_templates) { %w[./concourse/pipelines/template/bosh-pipeline.yml.erb ./concourse/pipelines/template/update-pipeline.yml.erb] }

    it 'contains only filtered templates' do
      expect(include_templates).to match_array(expected_include_templates)
    end

    it 'contains 2 elements' do
      expect(include_templates.length).to eq(2)
    end
  end

  context "when exclude filter is set" do
    let(:options) { OpenStruct.new(ops_automation: '.', input_pipelines: [], exclude_pipelines: %w[bosh-pipeline update-pipeline]) }
    let(:include_templates) { subject.filter }
    let(:expected_excluded_templates) { expected_all_pipelines_templates.reject { |path| path.include?('bosh-pipeline') || path.include?('update-pipeline') } }

    it 'contains only filtered templates' do
      expect(include_templates).to match_array(expected_excluded_templates)
    end

    it 'contains 2 elements' do
      expect(include_templates.length).to eq(expected_all_pipelines_templates.length - 2)
    end
  end
end
