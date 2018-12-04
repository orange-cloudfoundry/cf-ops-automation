# encoding: utf-8
# require 'spec_helper.rb'
require 'yaml'
require 'tmpdir'

describe 'list_used_ci_team task' do
  let(:teams_file) { File.join(@ci_deployment_overview, 'teams.yml') }

  def setup_secrets
    ops_depls_ci_deployment_yaml = <<~YAML
      ---
      ci-deployment:
        ops-depls:
          target_name: cw-pp-micro-for-ops-depls
          terraform_config:
            state_file_path: ops-depls/cloudfoundry/terraform-config
          pipelines:
            ops-depls-generated:
              config_file: master-depls/concourse-ops/pipelines/ops-depls-generated.yml
              vars_files:
              - micro-depls/concourse-micro/pipelines/credentials-auto-init.yml
              - ops-depls/ops-depls-versions.yml
            ops-depls-cf-apps-generated:
              config_file: master-depls/concourse-ops/pipelines/ops-depls-cf-apps-generated.yml
              vars_files:
              - master-depls/concourse-ops/pipelines/credentials-ops-depls-pipeline.yml
              - ops-depls/ops-depls-versions.yml
            ops-depls-news-generated:
              config_file: master-depls/concourse-ops/pipelines/ops-depls-news-generated.yml
              vars_files:
              - master-depls/concourse-ops/pipelines/credentials-ops-depls-pipeline.yml
              - ops-depls/ops-depls-versions.yml
            ops-depls-sync-helper-generated:
              config_file: master-depls/concourse-ops/pipelines/ops-depls-sync-helper-generated.yml
              team: my-custom-team-2
              vars_files:
              - micro-depls/concourse-micro/pipelines/credentials-git-config.yml
              - master-depls/concourse-ops/pipelines/credentials-ops-depls-sync-helper-pipeline.yml
            ops-depls-init-generated:
              config_file: master-depls/concourse-ops/pipelines/ops-depls-init-generated.yml
              team: my-custom-team-2
              vars_files:
              - micro-depls/concourse-micro/pipelines/credentials-git-config.yml
              - micro-depls/concourse-micro/pipelines/credentials-iaas-specific.yml
            ops-depls-s3-br-upload-generated:
              team: my-custom-team-1
            ops-depls-s3-stemcell-upload-generated:
    YAML
    master_depls_ci_deployment_yaml = <<~YAML
      ---
      ci-deployment:
        master-depls:
          target_name: cw-pp-micro-for-master-depls
          pipelines:
            master-depls-generated:
              config_file: micro-depls/concourse-master/pipelines/master-depls-generated.yml
              vars_files:
              - master-depls/master-depls-versions.yml
            master-depls-cf-apps-generated:
              config_file: micro-depls/concourse-master/pipelines/master-depls-cf-apps-generated.yml
              vars_files:
              - master-depls/master-depls-versions.yml
            master-depls-init-generated:
              config_file: micro-depls/concourse-master/pipelines/master-depls-init-generated.yml
              vars_files:
              - micro-depls/concourse-micro/pipelines/credentials-git-config.yml
    YAML


    @temp_dir = Dir.mktmpdir
    @ops_depls_file = File.join(@temp_dir, 'ops-depls')
    @ops_depls_dir = Dir.mkdir(@ops_depls_file)
    @master_depls_file = File.join(@temp_dir, 'master-depls')
    @master_depls_dir = Dir.mkdir(@master_depls_file)
    @ops_depls_ci_deployment_file =  File.join(@ops_depls_file, 'ci-deployment-overview.yml')
    @master_depls_ci_deployment_file = File.join(@master_depls_file, 'ci-deployment-overview.yml')

    File.write(@ops_depls_ci_deployment_file, ops_depls_ci_deployment_yaml)
    File.write(@master_depls_ci_deployment_file, master_depls_ci_deployment_yaml)
  end

  context 'when teams are found' do
    before(:context) do
      setup_secrets
      @secrets_dir = @temp_dir
      @ci_deployment_overview = Dir.mktmpdir

      @output = execute('-c concourse/tasks/list_used_ci_team/task.yml ' \
        '-i cf-ops-automation=. ' \
        "-i secrets=#{@secrets_dir} " \
        "-o ci-deployment-overview=#{@ci_deployment_overview} ",
        'SECRETS_PATH' => 'secrets')
    end

    after(:context) do
      FileUtils.rm_rf @ci_deployment_overview
      FileUtils.rm_rf @secrets_dir
    end

    it 'contains teams name' do
      expect(YAML.load_file(teams_file)).to match_array(['my-custom-team-1','my-custom-team-2'])
    end

    it 'contains a teams.yml file' do
      expect(File).to exist(teams_file)
    end
  end

  context 'when no teams are found' do
    before(:context) do
      @secrets_dir = Dir.mktmpdir
      @ci_deployment_overview = Dir.mktmpdir

      @output = execute('-c concourse/tasks/list_used_ci_team/task.yml ' \
        '-i cf-ops-automation=. ' \
        "-i secrets=#{@secrets_dir} " \
        "-o ci-deployment-overview=#{@ci_deployment_overview} ",
                        'SECRETS_PATH' => 'secrets')
    end

    after(:context) do
      FileUtils.rm_rf @ci_deployment_overview
      FileUtils.rm_rf @secrets_dir
    end

    it 'does not contain teams name' do
      expect(YAML.load_file(teams_file)).to match_array([])
    end
  end
end
