# encoding: utf-8
# require 'spec_helper.rb'
require 'yaml'

describe 'generate_manifest task' do

  generated_files = nil

  context 'when no template are detected' do

    generated_files = nil
    before(:context) do
      generated_files = Dir.mktmpdir

      @output = execute('-c concourse/tasks/generate-manifest.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        '-i additional-resource=spec/tasks/generate_manifest/additional-resource ' \
        "-o generated-files=#{generated_files} ",
        'YML_TEMPLATE_DIR' =>'',
        'SPRUCE_FILE_BASE_PATH' =>'',
        'YML_FILES' =>'',
        'SUFFIX' => '' )
    end

    after(:context) do
      FileUtils.rm_rf generated_files
    end

    it 'displays an error message but does not fail concourse task' do
      expect(@output).to include('ls: /*-tpl.yml: No such file or directory')
    end
  end

  context 'when templates are found' do

    before(:context) do
      generated_files = Dir.mktmpdir

      @output = execute('-c concourse/tasks/generate-manifest.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        '-i additional-resource=spec/tasks/generate_manifest/additional-resource ' \
        "-o generated-files=#{generated_files} ",
        'YML_TEMPLATE_DIR' => 'additional-resource/template',
        'SPRUCE_FILE_BASE_PATH' => 'credentials-resource/',
        'YML_FILES' => "'./credentials-resource/meta.yml ./credentials-resource/secrets.yml'",
        'SUFFIX' => '')
    end

    after(:context) do
      FileUtils.rm_rf generated_files
    end

    it 'generates a file per valid template' do
      expect(File.exist?(File.join(generated_files, 'first.yml'))).to be_truthy
      expect(File.exist?(File.join(generated_files, 'second.yml'))).to be_truthy
    end

    it 'displays an post-generate ignore message' do
      expect(@output).to include('ignoring post generate. No /post-generate.sh detected')
    end

    context 'when processing an invalid template' do

      before(:context) do
        generated_files = Dir.mktmpdir

        @output = execute('-c concourse/tasks/generate-manifest.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        '-i additional-resource=spec/tasks/generate_manifest/additional-resource ' \
        "-o generated-files=#{generated_files} ",
                          'YML_TEMPLATE_DIR' => 'additional-resource/invalid-template',
                          'SPRUCE_FILE_BASE_PATH' => 'credentials-resource/',
                          'YML_FILES' => "'./credentials-resource/meta.yml ./credentials-resource/secrets.yml'",
                          'SUFFIX' => '')
      end

      after(:context) do
        FileUtils.rm_rf generated_files
      end

      it 'display an error message' do
        expect(@output).to include('secrets.undefined_key').and \
          include('could not be found in the datastructure')
      end
    end


    context 'when a post generate script is detected' do

      before(:context) do
        generated_files = Dir.mktmpdir

        @output = execute('-c concourse/tasks/generate-manifest.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        '-i additional-resource=spec/tasks/generate_manifest/additional-resource ' \
        "-o generated-files=#{generated_files} ",
        'YML_TEMPLATE_DIR' => 'additional-resource/template',
        'SPRUCE_FILE_BASE_PATH' => 'credentials-resource/',
        'YML_FILES' => "'./credentials-resource/meta.yml ./credentials-resource/secrets.yml'",
        'SUFFIX' => '',
        'CUSTOM_SCRIPT_DIR' => 'additional-resource/a-root-depls'
        )
      end
      after(:context) do
        FileUtils.rm_rf generated_files
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
