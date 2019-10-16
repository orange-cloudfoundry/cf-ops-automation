require 'yaml'
require 'tmpdir'

describe 'check_configuration task' do
  let(:error_logfile) { File.join(@result_dir, 'errors.log') }

  context 'when successfully executed' do
    before(:context) do
      @result_dir = Dir.mktmpdir
      @config_resource = Dir.mktmpdir

      paas_templates_selected_paths = %w[hello-world-root-depls/bosh-deployment-sample shared-files]

      @output = execute('-c concourse/tasks/check_configuration/task.yml ' \
        '-i scripts-resource=. ' \
        '-i templates-resource=docs/reference_dataset/template_repository ' \
        "-i config-resource=#{@config_resource} " \
        "-o check-configuration-result=#{@result_dir} ",
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
      FileUtils.rm_rf @result_dir
      FileUtils.rm_rf @config_resource
    end

    it 'checks paas-templates config' do
      expect(@output).to \
        include('checking deployment-dependencies.yml @ templates-resource/hello-world-root-depls/bosh-deployment-sample').and \
          include('Paths to check: hello-world-root-depls/bosh-deployment-sample shared-files').and \
            include('Checking hello-world-root-depls/bosh-deployment-sample - templates-resource/hello-world-root-depls/bosh-deployment-sample').and \
              include('Checking shared-files - templates-resource/shared-files')
    end

    it 'generates no errors' do
      expect(File).to be_zero(error_logfile)
    end

    it 'checks config-resource consistency' do
      expect(@output).to include('Checking local scan consistency').and \
          include('Local secrets scan disabled for bosh-deployment-sample')
    end
  end

  context 'when failing' do
    let(:expected_errors) do
      ['ERROR: dummy-path does not exist (templates-resource/hello-world-root-depls/bosh-deployment-sample), please check related deployment-dependencies.yml',
       "\n",
       'ERROR: local_deployment_scan enabled in deployment-dependencies.yml for bosh-deployment-sample, but no config files (meta.yml, secrets.yml) detected at config-resource/hello-world-root-depls/bosh-deployment-sample/secrets',
       "\n"].join('')
    end

    before(:context) do
      @result_dir = Dir.mktmpdir
      @config_resource = Dir.mktmpdir

      paas_templates_selected_paths = %w[dummy-path]
      begin
        @output = execute('-c concourse/tasks/check_configuration/task.yml ' \
          '-i scripts-resource=. ' \
          '-i templates-resource=docs/reference_dataset/template_repository ' \
          "-i config-resource=#{@config_resource} " \
          "-o check-configuration-result=#{@result_dir} ",
                          'ROOT_DEPLOYMENT' => "hello-world-root-depls",
                          "DEPLOYMENT" => "bosh-deployment-sample",
                          "SCAN_PATHS" => "'#{paas_templates_selected_paths&.join(' ')}'",
                          "LOCAL_SECRETS_SCAN" => "true",
                          "GIT_SUBMODULES" => '')
      rescue FlyExecuteError => e
        @output = e.out
        @fly_error = e.err
        @fly_status = e.status
      end
    end

    after(:context) do
      FileUtils.rm_rf @result_dir
      FileUtils.rm_rf @config_resource
    end

    it 'fails' do
      expect(@fly_status.exitstatus).to eq(1)
    end

    it 'generates error log file' do
      expect(File).to exist(error_logfile)
    end

    it 'contains error messages in output file' do
      error_log = File.read(error_logfile)
      expect(error_log).to eq(expected_errors)
    end
  end
end
