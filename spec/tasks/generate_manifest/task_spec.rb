# encoding: utf-8
# require 'spec_helper.rb'
require 'yaml'

describe 'generate_manifest task' do

  context 'when no template are detected' do
    after(:context) do
      FileUtils.rm_rf @generated_files
    end

    before(:context) do
      @generated_files = Dir.mktmpdir

      @output = execute('-c concourse/tasks/generate-manifest.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        '-i additional-resource=spec/tasks/generate_manifest/additional-resource ' \
        "-o generated-files=#{@generated_files} ",
        'YML_TEMPLATE_DIR' =>'',
        'SPRUCE_FILE_BASE_PATH' =>'',
        'YML_FILES' =>'',
        'SUFFIX' => '' )
    end

    it 'displays an error message but does not fail concourse task' do
      expect(@output).to include('ls: /*-tpl.yml: No such file or directory')
    end
  end

  context 'when templates are found' do

    let(:tpl_yml_files) { Dir[File.join(@additional_resource, 'template', '*-tpl.yml')].sort }
    let(:operators_yml_files) { Dir[File.join(@additional_resource, 'template', '*-operators.yml')].sort }
    let(:generated_files_dir_content) { Dir[File.join(@generated_files,'*')] }

    before(:context) do
      @generated_files = Dir.mktmpdir
      @additional_resource = File.join(File.dirname(__FILE__), 'additional-resource')


      @output = execute('-c concourse/tasks/generate-manifest.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        "-i additional-resource=#{@additional_resource} " \
        "-o generated-files=#{@generated_files} ",
        'YML_TEMPLATE_DIR' => 'additional-resource/template',
        'SPRUCE_FILE_BASE_PATH' => 'credentials-resource/',
        'YML_FILES' => "'./credentials-resource/meta.yml ./credentials-resource/secrets.yml'",
        'SUFFIX' => '')
    end

    after(:context) do
      FileUtils.rm_rf @generated_files
    end

    it 'generates a file per valid template' do
      tpl_yml_files .map { |filename| File.basename(filename, '-tpl.yml') }
                    .each do |base_filename|
                      expected_filename = File.join(@generated_files, base_filename + '.yml')
                      expect(File).to exist(expected_filename), 'expected ' + base_filename + '.yml'
      end
    end

    it 'copies operators file to generated_files' do
      operators_yml_files .map { |filename| File.basename(filename) }
                          .each do |base_filename|
        expected_filename = File.join(@generated_files, base_filename)
        expect(File).to exist(expected_filename), 'expected ' + base_filename + 'to exist'
      end
    end

    it 'processes only -tpl.yml files and -operators.yml' do
      generated_files_dir_content = Dir[File.join(@generated_files, '*')]&.map! { |filename| File.basename(filename, '.yml') }
      expected_content = tpl_yml_files + operators_yml_files
      expected_content.map! { |filename| File.basename(filename, '.yml') }
                      .map! { |filename| filename.chomp('-tpl') }

      expect(generated_files_dir_content.size).to be_equal(expected_content.size)
    end

    it 'displays an post-generate ignore message' do
      expect(@output).to include('ignoring post generate. No /post-generate.sh detected')
    end

    context 'when processing an invalid template' do

      before(:context) do

        @output = execute('-c concourse/tasks/generate-manifest.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        '-i additional-resource=spec/tasks/generate_manifest/additional-resource ' \
        "-o generated-files=#{@generated_files} ",
                          'YML_TEMPLATE_DIR' => 'additional-resource/invalid-template',
                          'SPRUCE_FILE_BASE_PATH' => 'credentials-resource/',
                          'YML_FILES' => "'./credentials-resource/meta.yml ./credentials-resource/secrets.yml'",
                          'SUFFIX' => '')
      end

      after(:context) do
        FileUtils.rm_rf @generated_files
      end

      it 'display an error message' do
        expect(@output).to include('secrets.undefined_key').and \
          include('could not be found in the datastructure')
      end
    end


    context 'when a post generate script is detected' do

      before(:context) do

        @output = execute('-c concourse/tasks/generate-manifest.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        '-i additional-resource=spec/tasks/generate_manifest/additional-resource ' \
        "-o generated-files=#{@generated_files} ",
        'YML_TEMPLATE_DIR' => 'additional-resource/template',
        'SPRUCE_FILE_BASE_PATH' => 'credentials-resource/',
        'YML_FILES' => "'./credentials-resource/meta.yml ./credentials-resource/secrets.yml'",
        'SUFFIX' => '',
        'CUSTOM_SCRIPT_DIR' => 'additional-resource/a-root-depls'
        )
      end
      after(:context) do
        FileUtils.rm_rf @generated_files
      end

      it 'displays an execution message' do
        expect(@output).to include('post generation script detected')
      end

      %w[GENERATE_DIR BASE_TEMPLATE_DIR].each do |env_var|
        it "adds #{env_var} to available environment variables" do
          expect(@output).to include("variable #{env_var} is available")
        end
      end

    end
  end
end
