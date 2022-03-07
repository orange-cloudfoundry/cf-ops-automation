require 'rspec'
require 'tmpdir'
require 'deployment_deployers_config'
require 'directory_initializer'

describe DeploymentDeployersConfig do
  let(:root_deployment_name) { 'main_depls' }
  let(:deployment_name) { 'my_deployment' }
  let(:templates) do
    Dir.mktmpdir('templates')
  end
  let(:fail_on_inconsistency) { true}
  let(:secrets) do
    Dir.mktmpdir('secrets')
  end
  let(:root_deployment_init) do
    tf = 'terraform-config'
    init = DirectoryInitializer.new(root_deployment_name, secrets, templates, tf)
    init.setup_templates!
    init.setup_secrets!
    init
  end
  let(:deployment_factory) do
    DeploymentFactory.new(
      root_deployment_name,
      load_fixture(File.join('version-reference', 'default.yml'))
    )
  end
  let(:deployment_templates_path) { File.join(templates, root_deployment_name, deployment_name) }
  let(:deployment_secrets_path) { File.join(secrets, root_deployment_name, deployment_name) }

  describe '#initialize' do
    xit 'cannot initialize if a parameter is nil'
  end

  describe '#load_configs' do
    subject { described_class.new(deployment_name, deployment_templates_path, deployment_secrets_path, deployment_factory, fail_on_inconsistency: fail_on_inconsistency) }

    context 'when bosh and concourse deployers are enabled' do
      let(:loaded_config) { subject.load_configs }

      before do
        root_deployment_init.add_deployment(deployment_name)
        Dir.mkdir(File.join(deployment_templates_path, DeploymentDeployersConfig::CONCOURSE_CONFIG_DIRNAME))
      end

      it 'activates concourse deployer' do
        expect(loaded_config.details).to include('concourse' => { 'active' => true })
      end

      it 'activates bosh deployer' do
        expect(loaded_config.details).to include('releases', 'stemcells')
      end

      it 'marks deployement as enabled' do
        expect(loaded_config.details).to include('status' => 'enabled')
      end
    end

    context 'when terraform deployer only is enabled' do
      let(:loaded_config) { subject.load_configs }

      before do
        root_deployment_init
        Dir.mkdir(deployment_templates_path)
        Dir.mkdir(deployment_secrets_path)
        Dir.mkdir(File.join(deployment_templates_path, DeploymentDeployersConfig::TERRAFORM_CONFIG_DIRNAME))
      end

      it 'activates concourse deployer' do
        expect(loaded_config.details).to include('terraform' => { 'active' => true })
      end

      it 'ensures only terraform is enabled' do
        expect(loaded_config.details.keys).to match(%w[terraform status])
      end

      it 'marks deployement as enabled' do
        expect(loaded_config.details).to include('status' => 'enabled')
      end
    end

    context 'when kubernetes deployer only is enabled' do
      let(:loaded_config) { subject.load_configs }

      before do
        root_deployment_init
        Dir.mkdir(deployment_templates_path)
        Dir.mkdir(deployment_secrets_path)
        Dir.mkdir(File.join(deployment_templates_path, DeploymentDeployersConfig::KUBERNETES_CONFIG_DIRNAME))
      end

      it 'activates concourse deployer' do
        expect(loaded_config.details).to include('kubernetes' => { 'active' => true })
      end

      it 'ensures only terraform is enabled' do
        expect(loaded_config.details.keys).to match(%w[kubernetes status])
      end

      it 'marks deployement as enabled' do
        expect(loaded_config.details).to include('status' => 'enabled')
      end
    end

    context 'when no deployer is detected' do
      before do
        root_deployment_init
        Dir.mkdir(deployment_templates_path)
        Dir.mkdir(deployment_secrets_path)
      end

      it 'raises an error' do
        error_message = "Inconsistency detected: deployment <#{deployment_name}> is marked as active, but no #{DeploymentDeployersConfig::DEPLOYMENT_DEPENDENCIES_FILENAME}, nor other deployer config directory found (concourse-pipeline-config, k8s-config) at #{deployment_templates_path}"

        expect { subject.load_configs }.
          to raise_error(RuntimeError, error_message)
      end
    end
  end
end
