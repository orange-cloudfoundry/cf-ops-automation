require 'spec_helper'
require_relative '../../lib/pipeline_generator'

describe PipelineGenerator do
  describe "#initialize" do
    context "when options are passed" do
      let(:options) { { options: "are present" } }
      let(:pipeline_generator) { PipelineGenerator.new(options) }

      it "sets the received options" do
        expect(pipeline_generator.options).to eq(OpenStruct.new(options))
      end
    end
  end

  describe "#execute" do
    let(:depls) { "rspec_test_root_depl" }
    let(:paas_templates_path) { "paas_templates_path" }
    let(:secrets_path) { "secret/path" }
    let(:input_pipeline) { "ppln" }
    let(:git_submodule_path) { "git_submodule_path" }
    let(:options) do
      {
        paas_templates_path: paas_templates_path,
        depls: depls,
        secrets_path: secrets_path,
        input_pipelines: [input_pipeline],
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
    let(:config) { Config.new(shared_config, private_config) }
    let(:deployment_factory) do
      DeploymentFactory.new(depls, root_deployment_versions.versions, config)
    end
    let(:all_dependencies) { {} }
    let(:all_ci_deployments) { [] }
    let(:all_cf_apps) { [] }
    let(:git_submodules) { {} }
    let(:loaded_config) { { "key" => "value" } }
    let(:bosh_certificates) { BoshCertificates.new(secrets_path, PipelineGenerator::BOSH_CERT_LOCATIONS)  }
    let(:git_modules) { GitModules.new(git_submodule_path)  }

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
    let(:pipeline_generator) { PipelineGenerator.new(options) }

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

        expect(Config).to receive(:new).with(shared_config, private_config).
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
          with(depls, options, erb_context).
          and_return(template_processor)

        expect(template_processor).to receive(:process).
          with(input_pipeline).
          and_return({ "key" => "value" })

        expect(pipeline_generator.execute).to be_truthy
    end
  end

  describe "#display_warnings" do
    let(:pipeline_generator) { PipelineGenerator.new({}) }
    let(:warning1) { "warning1" }
    let(:warning2) { "warning2" }

    it "displays the warnings it contains" do
      pipeline_generator.warnings << warning1
      pipeline_generator.warnings << warning2

      expect{ pipeline_generator.display_warnings }.
        to output("#{warning1}\n#{warning2}\n").to_stdout
    end

  end
end

describe PipelineGenerator::Parser do
  xdescribe "those tests are randomly run and randomly fail /.parse" do
    let(:deployment_name) { "root_deployment" }

    context "when no root deployment is supplied" do
      let(:args) { [] }

      it "sends an error message" do
        expect_any_instance_of(OptionParser).to receive(:abort)
        described_class.parse(args)
      end
    end

    context "when just specifying the root deployment" do
      let(:args) { ["-d", deployment_name] }
      let(:parsed_options) do
        PipelineGenerator::DEFAULT_OPTIONS.merge({ depls: deployment_name })
      end

      it "uses the default options" do
        expect(described_class.parse(args)).to eq(parsed_options)
      end
    end

    context "when giving all the options" do
      let(:templates_path) { "template_path" }
      let(:git_submodule_path) { "git_submodule_path" }
      let(:secrets_path) { "secrets_path" }
      let(:output_path) { "output_path" }
      let(:automation_path) { "automation_path" }
      let(:input) { "input" }
      let(:args) do
        [
          "-d", deployment_name,
          "-t", templates_path,
          "-s", git_submodule_path,
          "-p", secrets_path,
          "-o", output_path,
          "-a", automation_path,
          "-i", input,
          "--no-dump"
        ]
      end

      let(:parsed_options) {
        PipelineGenerator::DEFAULT_OPTIONS.merge({
          depls: deployment_name,
          git_submodule_path: git_submodule_path,
          secrets_path: secrets_path,
          output_path: output_path,
          ops_automation: automation_path,
          dump_output: false,
          paas_templates_path: templates_path
        })
      }

      it "overwrites the default options" do
        expect(described_class.parse(args)).to eq(parsed_options)
      end
    end
  end
end
