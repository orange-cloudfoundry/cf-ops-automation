# encoding: utf-8
require 'yaml'
require 'tmpdir'
require_relative '../terraform_plan_cloudfoundry/task_spec'

describe 'terraform_apply_cloudfoundry task' do
  SKIP_TMP_FILE_CLEANUP = false

  context 'Pre-requisite' do
    let(:task) { YAML.load_file 'concourse/tasks/terraform_apply_cloudfoundry.yml' }

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

      @output = execute('-c concourse/tasks/terraform_apply_cloudfoundry.yml ' \
        '-i secret-state-resource=spec/tasks/terraform_apply_cloudfoundry/secret-state-resource ' \
        '-i spec-resource=spec/tasks/terraform_apply_cloudfoundry/spec-resource ' \
        "-i terraform-tfvars=#{@terraform_tfvars} " \
        "-o generated-files=#{@generated_files} " \
        "-o spec-applied=#{@spec_applied} ",
                        'SPEC_PATH' => 'non-empty-spec-path',
                        'IAAS_SPEC_PATH' => 'non-empty-iaas-spec-path',
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
      expect(@output).to include("provider.cloudfoundry #{EXPECTED_PROVIDER_CLOUDFOUNDRY_VERSION}")
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

    it 'applies to add resources' do
      expect(@output).to include('Apply complete!').and \
        include('Resources: 5 added, 0 changed, 0 destroyed.')
    end

    it 'processes all spec files' do
      expect(File).to exist(File.join(@generated_files,'spec.txt')).and \
      exist(File.join(@generated_files,'secrets.txt'))
    end

    it 'processes all iaas spec files' do
      expect(File).to exist(File.join(@generated_files,'my-iaas-spec.txt')).and \
      exist(File.join(@generated_files,'my-iaas-secret-spec.txt'))
    end

    it 'copies all found spec files into spec-applied output' do
      spec_files_in_spec_resource = Dir.entries(File.join(@spec_resource, 'spec'))
      spec_files_in_iaas_spec_resource = Dir.entries(File.join(@spec_resource, 'spec-my-iaas'))
      spec_files_in_secret_resource = Dir.entries(File.join(@secret_resource, 'spec'))
      spec_files_in_iaas_secret_resource = Dir.entries(File.join(@secret_resource, 'spec-my-iaas'))

      all_spec_files = (spec_files_in_spec_resource + spec_files_in_iaas_spec_resource + spec_files_in_secret_resource + spec_files_in_iaas_secret_resource).uniq.sort
      expect(Dir.entries(@spec_applied).sort).to eq(all_spec_files.sort)
    end

    it 'generates a terraform state file in generated-files output' do
      expect(File).to exist(File.join(@generated_files, 'terraform.tfstate'))
    end

    it 'copies terraform-tfvars files in generated-files output' do
      expect(File).to exist(File.join(@generated_files, 'terraform.tfvars'))
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
