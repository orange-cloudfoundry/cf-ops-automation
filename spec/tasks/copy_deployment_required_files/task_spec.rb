# require 'spec_helper.rb'
require 'yaml'
require 'tmpdir'

describe 'copy_deployment_required_files task' do
  context 'when no manifest has been generated' do
    before(:context) do
      @generated_files = Dir.mktmpdir
      @additional_resource = Dir.mktmpdir
      FileUtils.touch(File.join(@additional_resource, 'an-auto-generated-file-1.yml'))
      FileUtils.touch(File.join(@additional_resource, 'an-auto-generated-file-2.yml'))
      @manifest_name = 'not-existing-manifest.yml'

      @output = execute('-c concourse/tasks/copy_deployment_required_files.yml ' \
        '-i scripts-resource=. ' \
        '-i template-resource=spec/tasks/copy_deployment_required_files/template-resource ' \
        '-i credentials-resource=spec/tasks/copy_deployment_required_files/credentials-resource ' \
        "-i additional-resource=#{@additional_resource} " \
        "-o generated-files=#{@generated_files} ",
                        'CUSTOM_SCRIPT_DIR' => '',
                        'SECRETS_DIR' => '',
                        'MANIFEST_NAME' => @manifest_name)
    end

    after(:context) do
      FileUtils.rm_rf @generated_files if File.exist?(@generated_files)
      FileUtils.rm_rf @additional_resource if File.exist?(@additional_resource)
    end

    it 'displays an message checking manifest existence' do
      expect(@output).to include("checking manifest '#{@manifest_name}' existence")
    end

    it 'displays an message ignoring manifest existence' do
      expect(@output).to include("ignoring '#{@manifest_name}'. No manifest detected.")
    end

    it 'adds additional resource to generated' do
      additional_resource_dir_content = Dir[File.join(@additional_resource, '*')]&.map! { |filename| File.basename(filename) }
      generated_files_dir_content = Dir[File.join(@generated_files, '*')]&.map! { |filename| File.basename(filename) }

      expect(generated_files_dir_content).to match_array(additional_resource_dir_content)
    end
  end

  context 'when no manifest generated but a default manifest is detected' do
    before(:context) do
      @generated_files = Dir.mktmpdir
      @additional_resource = Dir.mktmpdir
      @manifest_name = 'default-manifest-depls.yml'
      FileUtils.touch(File.join(@additional_resource, 'an-auto-generated-file-1.yml'))
      FileUtils.touch(File.join(@additional_resource, 'an-auto-generated-file-2.yml'))

      @output = execute('-c concourse/tasks/copy_deployment_required_files.yml ' \
        '-i scripts-resource=. ' \
        '-i template-resource=spec/tasks/copy_deployment_required_files/template-resource ' \
        '-i credentials-resource=spec/tasks/copy_deployment_required_files/credentials-resource ' \
        "-i additional-resource=#{@additional_resource} " \
        "-o generated-files=#{@generated_files} ",
                        'CUSTOM_SCRIPT_DIR' => 'template-resource/default-manifest-depls',
                        'SECRETS_DIR' => 'credentials-resource/default-manifest-depls',
                        'MANIFEST_NAME' => @manifest_name)
    end

    after(:context) do
      FileUtils.rm_rf @generated_files if File.exist?(@generated_files)
      FileUtils.rm_rf @additional_resource if File.exist?(@additional_resource)
    end

    it 'displays an execution message' do
      expect(@output).to include("default '#{@manifest_name}' detected.")
    end

    it 'exists a manifest file in generation dir' do
      expect(File).to exist(File.join(@generated_files, @manifest_name))
    end

    it 'adds additional resource to generated' do
      additional_resource_dir_content = Dir[File.join(@additional_resource, '*')]&.map! { |filename| File.basename(filename) }
      generated_files_dir_content = Dir[File.join(@generated_files, '*')]&.map! { |filename| File.basename(filename) }

      expect(generated_files_dir_content).to match_array(additional_resource_dir_content.push(@manifest_name))
    end
  end

  context 'when a generated manifest is detected' do
    before(:context) do
      @generated_files = Dir.mktmpdir
      @additional_resource = 'spec/tasks/copy_deployment_required_files/additional-resource'
      @manifest_name = 'a-depls.yml'

      @output = execute('-c concourse/tasks/copy_deployment_required_files.yml ' \
        '-i scripts-resource=. ' \
        '-i template-resource=spec/tasks/copy_deployment_required_files/template-resource ' \
        '-i credentials-resource=spec/tasks/copy_deployment_required_files/credentials-resource ' \
        "-i additional-resource=#{@additional_resource} " \
        "-o generated-files=#{@generated_files} ",
                        'CUSTOM_SCRIPT_DIR' => 'template-resource/a-depls',
                        'SECRETS_DIR' => 'credentials-resource/a-depls',
                        'MANIFEST_NAME' => @manifest_name)
    end

    after(:context) do
      FileUtils.rm_rf @generated_files if File.exist?(@generated_files)
    end

    it 'displays an execution message' do
      expect(@output).to include("'#{@manifest_name}' already exists in additional-resource. Skipping copy !!!")
    end

    it 'exists a manifest file in generation dir' do
      expect(File).to exist(File.join(@generated_files, @manifest_name))
    end

    it 'adds additional resource to generated' do
      additional_resource_dir_content = Dir[File.join(@additional_resource, '*')]&.map! { |filename| File.basename(filename) }

      additional_resource_dir_content&.each do |filename|
        expect(File).to exist(File.join(@generated_files, filename))
      end
    end
  end
end
