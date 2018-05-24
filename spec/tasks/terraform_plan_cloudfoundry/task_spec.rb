# encoding: utf-8
require 'yaml'
require 'tmpdir'

describe 'terraform_plan_cloudfoundry task' do
  EXPECTED_TERRAFORM_IMAGE_TAG = '6a780dbedb7882374c615e6f7d1b97a88efd5896'.freeze
  EXPECTED_TERRAFORM_VERSION = '0.11.7'.freeze
  EXPECTED_PROVIDER_CLOUDFOUNDRY_VERSION = 'v0.9.1'.freeze
  SKIP_TMP_FILE_CLEANUP = false

  context 'Pre-requisite' do
    let(:task) { YAML.load_file 'concourse/tasks/terraform_plan_cloudfoundry.yml' }

    it 'uses official orange-cloudfoundry/terraform image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match('orangecloudfoundry/terraform')
    end

    it 'uses a tagged image' do
      docker_tag_used = task['image_resource']['source']['tag'].to_s
      expect(docker_tag_used).to match(EXPECTED_TERRAFORM_IMAGE_TAG)
    end
  end

  context 'when pre-requisite are valid' do
    before(:context) do
      @generated_files = Dir.mktmpdir
      @spec_applied = Dir.mktmpdir
      @terraform_tfvars = File.join(File.dirname(__FILE__), 'terraform-tfvars')

      @output = execute('-c concourse/tasks/terraform_plan_cloudfoundry.yml ' \
        '-i secret-state-resource=spec/tasks/terraform_plan_cloudfoundry/secret-state-resource ' \
        '-i spec-resource=spec/tasks/terraform_plan_cloudfoundry/spec-resource ' \
        "-i terraform-tfvars=#{@terraform_tfvars} " \
        "-o generated-files=#{@generated_files} " \
        "-o spec-applied=#{@spec_applied} ",
                        'SPEC_PATH' => '',
                        'IAAS_SPEC_PATH' => '',
                        'SECRET_STATE_FILE_PATH' => 'no-tfstate-dir')
    end

    after(:context) do
      unless SKIP_TMP_FILE_CLEANUP
        FileUtils.rm_rf @generated_files
        FileUtils.rm_rf @spec_applied
      end
    end

    it 'ensures terraform version is correct' do
      expect(@output).to include("Terraform v#{EXPECTED_TERRAFORM_VERSION}")
    end

    it 'ensures terraform cloudfoundry provider version is correct' do
      expect(@output).to include("provider.cloudfoundry #{EXPECTED_PROVIDER_CLOUDFOUNDRY_VERSION}")
    end

    it 'ensures tfvars files are also in generated-files' do
      expected_dirs = Dir.entries(@terraform_tfvars) << '.gitkeep'
      expect(Dir.entries(@generated_files).sort).to eq(expected_dirs.sort)
    end

  end

  context 'when specs are only in template' do

    before(:context) do
      @generated_files = Dir.mktmpdir
      @spec_applied = Dir.mktmpdir
      @terraform_tfvars = File.join(File.dirname(__FILE__), 'terraform-tfvars')

      @output = execute('-c concourse/tasks/terraform_plan_cloudfoundry.yml ' \
        '-i secret-state-resource=spec/tasks/terraform_plan_cloudfoundry/secret-state-resource ' \
        '-i spec-resource=spec/tasks/terraform_plan_cloudfoundry/spec-resource ' \
        "-i terraform-tfvars=#{@terraform_tfvars} " \
        "-o generated-files=#{@generated_files} " \
        "-o spec-applied=#{@spec_applied} ",
                        'SPEC_PATH' => 'spec-only',
                        'IAAS_SPEC_PATH' => 'spec-dummy-iaas',
                        'SECRET_STATE_FILE_PATH' => 'no-tfstate-dir')
    end

    after(:context) do
      unless SKIP_TMP_FILE_CLEANUP
        FileUtils.rm_rf @generated_files
        FileUtils.rm_rf @spec_applied
      end
    end

    it 'plans to add only one change' do
      expect(@output).to include('Plan:')
        include('1 to add, 0 to change, 0 to destroy.')
    end

    it 'emulates spec file processing' do
      expect(@output).to include('content:').and \
        include('"this file is generated by terraform spec_only resource !"')
    end

    it 'contains only spec files in spec-applied' do
      expect(Dir.entries(@spec_applied).sort).to eq(%w[. .. create-file.tf].sort)
    end

    it 'copies terraform-tfvars files in generated-files output' do
      cred_dir = %w[.gitkeep]

      expected_dirs = Dir.entries(@terraform_tfvars) + cred_dir
      expect(Dir.entries(@generated_files).sort).to eq(expected_dirs.sort)
    end

  end

  context 'when specs are in resource dirs (template + secret + iaas)' do

    before(:context) do
      @generated_files = Dir.mktmpdir
      @spec_applied = Dir.mktmpdir
      @spec_resource = File.join(File.dirname(__FILE__), 'spec-resource')
      @secret_resource = File.join(File.dirname(__FILE__), 'secret-state-resource')
      @terraform_tfvars = File.join(File.dirname(__FILE__), 'terraform-tfvars')

      @output = execute('-c concourse/tasks/terraform_plan_cloudfoundry.yml ' \
        "-i secret-state-resource=#{@secret_resource} " \
        "-i spec-resource=#{@spec_resource} " \
        "-i terraform-tfvars=#{@terraform_tfvars} " \
        "-o generated-files=#{@generated_files} " \
        "-o spec-applied=#{@spec_applied} ",
                        'SPEC_PATH' => 'spec',
                        'IAAS_SPEC_PATH' => 'spec-my-iaas',
                        'SECRET_STATE_FILE_PATH' => 'no-tfstate-dir')
    end

    after(:context) do
      unless SKIP_TMP_FILE_CLEANUP
        FileUtils.rm_rf @generated_files
        FileUtils.rm_rf @spec_applied
      end
    end

    it 'plans to add resources' do
      expect(@output).to include('Plan:').and \
        include('5 to add, 0 to change, 0 to destroy.')
    end

    it 'emulates all spec files processing' do
      expect(@output).to include('content:').and \
        include('"this file is generated by terraform spec resource !"').and \
        include('"this file is generated by terraform my_iaas_spec resource !"').and \
        include('"this file is generated by terraform secret resource !"').and \
        include('"this file is generated by terraform my_iaas_secret_spec resource !"').and \
        include('"this file is generated by terraform spec resource module! with input param : a value"')
    end

    it 'copies all found spec files into spec-applied output' do
      spec_files_in_spec_resource = Dir.entries(File.join(@spec_resource, 'spec'))
      spec_files_in_iaas_spec_resource = Dir.entries(File.join(@spec_resource, 'spec-my-iaas'))
      spec_files_in_secret_resource = Dir.entries(File.join(@secret_resource, 'spec'))
      spec_files_in_iaas_secret_resource = Dir.entries(File.join(@secret_resource, 'spec-my-iaas'))
      all_spec_files = (spec_files_in_spec_resource + spec_files_in_iaas_spec_resource + spec_files_in_secret_resource + spec_files_in_iaas_secret_resource).uniq.sort
      expect(Dir.entries(@spec_applied).sort).to eq(all_spec_files.sort)
    end

    it 'copies terraform-tfvars files in generated-files output' do
      Dir.entries(@terraform_tfvars).each do |filename|
        expect(File).to exist(File.join(@generated_files, filename))
      end
    end

  end

  context 'when secrets overrides template (e.g. specs or others)' do

    before(:context) do
      @generated_files = Dir.mktmpdir
      @spec_applied = Dir.mktmpdir
      @terraform_tfvars = Dir.mktmpdir
      @spec_resource = File.join(File.dirname(__FILE__), 'spec-resource')
      @secret_resource = File.join(File.dirname(__FILE__), 'secret-state-resource')
      @spec_path = 'override'

      @output = execute('-c concourse/tasks/terraform_plan_cloudfoundry.yml ' \
        "-i secret-state-resource=#{@secret_resource} " \
        "-i spec-resource=#{@spec_resource} " \
        "-i terraform-tfvars=#{@terraform_tfvars} " \
        "-o generated-files=#{@generated_files} " \
        "-o spec-applied=#{@spec_applied} ",
                        'SPEC_PATH' => @spec_path,
                        'IAAS_SPEC_PATH' => 'dummy',
                        'SECRET_STATE_FILE_PATH' => 'no-tfstate-dir')
    end

    after(:context) do
      unless SKIP_TMP_FILE_CLEANUP
        FileUtils.rm_rf @generated_files
        FileUtils.rm_rf @spec_applied
        FileUtils.rm_rf @terraform_tfvars
      end
    end

    it 'plans to add only one resource' do
      expect(@output).to include('Plan:')
      include('1 to add, 0 to change, 0 to destroy.')
    end

    it 'emulates secrets spec files processing' do
      expect(@output).to include('content:').and \
        include('"this file is generated by terraform secret resource !"')
    end

    it 'ignores specs from spec-resource' do
      expect(@output).not_to include('"this file is generated by terraform spec resource !"')
    end

    it 'copies secret spec files into spec-applied output' do
      spec_files_in_secret_resource = Dir.entries(File.join(@secret_resource, @spec_path)).sort
      expect(Dir.entries(@spec_applied).sort).to eq(spec_files_in_secret_resource)
    end

    it 'does not contain any files in generated-files output' do
      expect(Dir.entries(@generated_files).sort).to eq(%w[. .. .gitkeep].sort)
    end

  end

end
