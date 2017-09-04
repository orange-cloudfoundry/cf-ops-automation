# encoding: utf-8
require 'yaml'
require 'tmpdir'

describe 'terraform_apply_cloudfoundry task' do
  EXPECTED_TERRAFORM_VERSION='0.9.8'
  EXPECTED_PROVIDER_CLOUDFOUNDRY_VERSION='v0.7.3'

  context 'when pre-requisite are valid' do
    before(:context) do
      @generated_files = Dir.mktmpdir
      @spec_applied = Dir.mktmpdir
      @terraform_tfvars = File.join(File.dirname(__FILE__), 'terraform-tfvars')

      @output = execute('-c concourse/tasks/terraform_apply_cloudfoundry.yml ' \
        '-i secret-state-resource=spec/tasks/terraform_apply_cloudfoundry/secret-state-resource ' \
        '-i spec-resource=spec/tasks/terraform_apply_cloudfoundry/spec-resource ' \
        "-i terraform-tfvars=#{@terraform_tfvars} " \
        "-o generated-files=#{@generated_files} " \
        "-o spec-applied=#{@spec_applied} ",
                        'SPEC_PATH' => '',
                        'SECRET_STATE_FILE_PATH' => 'no-tfstate-dir')
    end

    after(:context) do
      FileUtils.rm_rf @generated_files
      FileUtils.rm_rf @spec_applied
    end

    it 'ensures terraform version is correct' do
      expect(@output).to include("Terraform v#{EXPECTED_TERRAFORM_VERSION}")
    end

    it 'ensures terraform cloudfoundry provider version is correct' do
      expect(@output).to include("terraform-provider-cloudfoundry-#{EXPECTED_PROVIDER_CLOUDFOUNDRY_VERSION} has been installed")
    end

    it 'ensures tfvars files are also in generated-files' do
      expect(File).to exist(File.join(@generated_files, 'terraform.tfvars'))
    end

  end

  context 'when specs are only in spec-resource' do

    before(:context) do
      @generated_files = Dir.mktmpdir
      @spec_applied = Dir.mktmpdir
      @terraform_tfvars = File.join(File.dirname(__FILE__), 'terraform-tfvars')

      @output = execute('-c concourse/tasks/terraform_apply_cloudfoundry.yml ' \
        '-i secret-state-resource=spec/tasks/terraform_apply_cloudfoundry/secret-state-resource ' \
        '-i spec-resource=spec/tasks/terraform_apply_cloudfoundry/spec-resource ' \
        "-i terraform-tfvars=#{@terraform_tfvars} " \
        "-o generated-files=#{@generated_files} " \
        "-o spec-applied=#{@spec_applied} ",
        'SPEC_PATH' =>'spec-only',
        'SECRET_STATE_FILE_PATH' => 'no-tfstate-dir' )
    end

    after(:context) do
      FileUtils.rm_rf @generated_files
      FileUtils.rm_rf @spec_applied
    end

    it 'applies to add only one resource' do
      expect(@output).to include('Apply complete!')
        include('Resources: 1 to add, 0 to change, 0 to destroy.')
    end

    it 'processes spec file' do
      expect(File).to exist(File.join(@generated_files,'spec-only.txt'))
    end

    it 'contains only spec files in spec-applied' do
      expect(Dir.entries(@spec_applied).sort).to eq(%w[. .. create-file.tf].sort)
    end

    it 'generates a terraform state file in generated-files output' do
      expect(File).to exist(File.join(@generated_files, 'terraform.tfstate'))
    end

    it 'copies terraform-tfvars files in generated-files output' do
      expect(File).to exist(File.join(@generated_files, 'terraform.tfvars'))
    end

    it 'matches files in generated-files output' do
      expected_files = %w[. .. .gitkeep terraform.tfvars terraform.tfstate spec-only.txt].sort
      expect(Dir.entries(@generated_files).sort).to eq(expected_files)
    end

  end

  context 'when specs are in resource dirs' do

    before(:context) do
      @generated_files = Dir.mktmpdir
      @spec_applied = Dir.mktmpdir
      @spec_resource = File.join(File.dirname(__FILE__), 'spec-resource')
      @secret_resource = File.join(File.dirname(__FILE__), 'secret-state-resource')
      @terraform_tfvars = File.join(File.dirname(__FILE__), 'terraform-tfvars')

      @output = execute('-c concourse/tasks/terraform_apply_cloudfoundry.yml ' \
        "-i secret-state-resource=#{@secret_resource} " \
        "-i spec-resource=#{@spec_resource} " \
        "-i terraform-tfvars=#{@terraform_tfvars} " \
        "-o generated-files=#{@generated_files} " \
        "-o spec-applied=#{@spec_applied} ",
                        'SPEC_PATH' =>'spec',
                        'SECRET_STATE_FILE_PATH' => 'no-tfstate-dir')
    end

    after(:context) do
      FileUtils.rm_rf @generated_files
      FileUtils.rm_rf @spec_applied
    end

    it 'applies to add resources' do
      expect(@output).to include('Apply complete!')
      include('Resources: 2 to add, 0 to change, 0 to destroy.')
    end

    it 'processes all spec files' do
      expect(File).to exist(File.join(@generated_files,'spec.txt')).and \
      exist(File.join(@generated_files,'secrets.txt'))
    end

    it 'copies all found spec files into spec-applied output' do
      spec_files_in_spec_resource = Dir.entries(File.join(@spec_resource, 'spec'))
      spec_files_in_secret_resource = Dir.entries(File.join(@secret_resource, 'spec'))
      all_spec_files = (spec_files_in_spec_resource + spec_files_in_secret_resource).uniq.sort
      expect(Dir.entries(@spec_applied).sort).to eq(all_spec_files.sort)
    end

    it 'generates a terraform state file in generated-files output' do
      expect(File).to exist(File.join(@generated_files, 'terraform.tfstate'))
    end

    it 'copies terraform-tfvars files in generated-files output' do
      expect(File).to exist(File.join(@generated_files,'terraform.tfvars'))
    end

  end

  context 'when secrets specs overrides others' do

    before(:context) do
      @generated_files = Dir.mktmpdir
      @spec_applied = Dir.mktmpdir
      @terraform_tfvars = Dir.mktmpdir
      @spec_resource = File.join(File.dirname(__FILE__), 'spec-resource')
      @secret_resource = File.join(File.dirname(__FILE__), 'secret-state-resource')
      @spec_path = 'override'

      @output = execute('-c concourse/tasks/terraform_apply_cloudfoundry.yml ' \
        "-i secret-state-resource=#{@secret_resource} " \
        "-i spec-resource=#{@spec_resource} " \
        "-i terraform-tfvars=#{@terraform_tfvars} " \
        "-o generated-files=#{@generated_files} " \
        "-o spec-applied=#{@spec_applied} ",
                        'SPEC_PATH' => @spec_path,
                        'SECRET_STATE_FILE_PATH' => 'no-tfstate-dir')
    end

    after(:context) do
      FileUtils.rm_rf @generated_files
      FileUtils.rm_rf @spec_applied
      FileUtils.rm_rf @terraform_tfvars
    end

    it 'applies to add only one resource' do
      expect(@output).to include('Apply complete!')
      include('Resources: 1 to add, 0 to change, 0 to destroy.')
    end

    it 'process secrets spec files' do
      expect(File).to exist(File.join(@generated_files,'secrets.txt'))

    end

    it 'ignores specs from spec-resource' do
      expect(File).not_to exist(File.join(@generated_files,'spec.txt'))
    end

    it 'copies secret spec files into spec-applied output' do
      spec_files_in_secret_resource = Dir.entries(File.join(@secret_resource, @spec_path)).sort
      expect(Dir.entries(@spec_applied).sort).to eq(spec_files_in_secret_resource)
    end

    it 'generates a terraform state file in generated-files output' do
      expect(File).to exist(File.join(@generated_files, 'terraform.tfstate'))
    end

    it 'matches files in generated-files output' do
      expected_files = %w[. .. .gitkeep terraform.tfstate secrets.txt].sort
      expect(Dir.entries(@generated_files).sort).to eq(expected_files)
    end
  end

end
