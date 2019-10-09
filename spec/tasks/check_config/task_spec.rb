require 'yaml'
require 'tmpdir'

describe 'check_configuration task' do
  context 'when executed' do
    before(:context) do
      @result = Dir.mktmpdir
      @config_resource = Dir.mktmpdir

      paas_templates_selected_paths = %w[hello-world-root-depls/bosh-deployment-sample shared-files]

      @output = execute('-c concourse/tasks/check_configuration/task.yml ' \
        '-i scripts-resource=. ' \
        '-i templates-resource=docs/reference_dataset/template_repository ' \
        "-i config-resource=#{@config_resource} " \
        "-o check-configuration-result=#{@result} ",
                        'ROOT_DEPLOYMENT' => "hello-world-root-depls",
                        "DEPLOYMENT" => "bosh-deployment-sample",
                        "SCAN_PATHS" => "'#{paas_templates_selected_paths&.join(' ')}'",
                        "LOCAL_SECRETS_SCAN" => "false",
                        "GIT_SUBMODULES" => '')
    rescue FlyExecuteError => e
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
    end

    after(:context) do
      FileUtils.rm_rf @result
      FileUtils.rm_rf @config_resource
    end

    it 'checks paas-templates config' do
      expect(@output).to \
        include('checking deployment-dependencies.yml @ templates-resource/hello-world-root-depls/bosh-deployment-sample').and \
          include('Paths to check: hello-world-root-depls/bosh-deployment-sample shared-files').and \
            include('Checking hello-world-root-depls/bosh-deployment-sample - templates-resource/hello-world-root-depls/bosh-deployment-sample').and \
              include('Checking shared-files - templates-resource/shared-files')
    end


    it 'checks config-resource consistency' do
      expect(@output).to include('Checking local scan consistency').and \
          include('Local secrets scan disabled for bosh-deployment-sample')
    end
  end
end
