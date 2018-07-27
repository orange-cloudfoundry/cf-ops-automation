
# require 'spec_helper.rb'
require 'yaml'
require 'tmpdir'

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
                        'IAAS_TYPE' => '',
                        'YML_TEMPLATE_DIR' => '',
                        'SPRUCE_FILE_BASE_PATH' => '',
                        'YML_FILES' => '',
                        'SUFFIX' => '')
    end

    it 'displays an error message but does not fail concourse task' do
      expect(@output).to include('ls: /*-tpl.yml: No such file or directory')
    end
  end

  context 'when only common templates are found' do
    let(:paas_template_path) { File.join(@additional_resource, 'template') }
    let(:tpl_yml_files) { Dir[File.join(paas_template_path, '*-tpl.yml')].sort }
    let(:operators_yml_files) { Dir[File.join(paas_template_path, '*-operators.yml')].sort }
    let(:vars_yml_files) { Dir[File.join(paas_template_path, '*-vars.yml')].sort }
    let(:unspruced_yml_files) { (operators_yml_files + vars_yml_files).sort }
    let(:generated_files_dir_content) { Dir[File.join(@generated_files, '*')] }

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
        expect(File).to exist(expected_filename), 'expected ' + base_filename + ' to exist'
      end
    end

    it 'processes only common *-tpl.yml files, *-operators.yml and *-vars.yml' do
      generated_files_dir_content = Dir[File.join(@generated_files, '*')]&.map! { |filename| File.basename(filename, '.yml') }
      expected_content = tpl_yml_files + unspruced_yml_files
      expected_content.map! { |filename| File.basename(filename, '.yml') }
                      .map! { |filename| filename.chomp('-tpl') }

      expect(generated_files_dir_content).to match_array(expected_content)
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
                          'CUSTOM_SCRIPT_DIR' => 'additional-resource/a-root-depls')
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

  context 'when common and iaas specific templates are found' do
    let(:iaas_type) { 'openstack' }
    let(:paas_template_path) { File.join(@additional_resource, 'template-with-iaas') }
    let(:tpl_yml_files) { Dir[File.join(paas_template_path, '*-tpl.yml')].sort }
    let(:operators_yml_files) { Dir[File.join(paas_template_path, '*-operators.yml')].sort }
    let(:vars_yml_files) { Dir[File.join(paas_template_path, '*-vars.yml')].sort }
    let(:unspruced_yml_files) { (operators_yml_files + vars_yml_files).sort }
    let(:iaas_tpl_yml_files) { Dir[File.join(paas_template_path, iaas_type, '*-tpl.yml')].sort }
    let(:iaas_operators_yml_files) { Dir[File.join(paas_template_path, iaas_type, '*-operators.yml')].sort }
    let(:iaas_vars_yml_files) { Dir[File.join(paas_template_path, iaas_type, '*-vars.yml')].sort }
    let(:iaas_unspruced_yml_files) { (iaas_operators_yml_files + iaas_vars_yml_files).sort }
    let(:generated_files_dir_content) { Dir[File.join(@generated_files, '*')] }

    before(:context) do
      @generated_files = Dir.mktmpdir
      @additional_resource = File.join(File.dirname(__FILE__), 'additional-resource')

      @output = execute('-c concourse/tasks/generate-manifest.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        "-i additional-resource=#{@additional_resource} " \
        "-o generated-files=#{@generated_files} ",
                        'YML_TEMPLATE_DIR' => 'additional-resource/template-with-iaas',
                        'SPRUCE_FILE_BASE_PATH' => 'credentials-resource/',
                        'YML_FILES' => "'./credentials-resource/meta.yml ./credentials-resource/secrets.yml'",
                        'SUFFIX' => '',
                        'IAAS_TYPE' => 'openstack')
    end

    after(:context) do
      FileUtils.rm_rf @generated_files
    end

    it 'generates a file per valid template' do
      all_yml = tpl_yml_files + iaas_tpl_yml_files
      all_yml
        .map { |filename| File.basename(filename, '-tpl.yml') }
        .each do |base_filename|
        expected_filename = File.join(@generated_files, base_filename + '.yml')
        expect(File).to exist(expected_filename), 'expected ' + base_filename + '.yml'
      end
    end

    it 'copies vars file to generated_files' do
      all_operators = unspruced_yml_files + iaas_operators_yml_files
      all_operators
        .map { |filename| File.basename(filename) }
        .each do |base_filename|
        expected_filename = File.join(@generated_files, base_filename)
        expect(File).to exist(expected_filename), 'expected ' + base_filename + ' to exist'
      end
    end

    it 'processes only shared and iaas-specific files (ie -tpl.yml, -operators.yml and -vars.yml)' do
      generated_files_dir_content = Dir[File.join(@generated_files, '*')]&.map! { |filename| File.basename(filename, '.yml') }
      expected_content = tpl_yml_files + unspruced_yml_files + iaas_tpl_yml_files + iaas_unspruced_yml_files
      expected_content.map! { |filename| File.basename(filename, '.yml') }
                      .map! { |filename| filename.chomp('-tpl') }

      expect(generated_files_dir_content).to match_array(expected_content)
    end
  end

  context 'when secrets.yml and meta.yml are empty' do
    before(:context) do
      @generated_files = Dir.mktmpdir
      @credentials_dir = Dir.mktmpdir
      @additional_resource = Dir.mktmpdir

      File.open(File.join(@additional_resource,'dummy-tpl.yml'), 'w') do |file|
        file.write <<~YAML
          dummy_yaml:
            empty: true
        YAML
      end

      @output = execute('-c concourse/tasks/generate-manifest.yml ' \
        '-i scripts-resource=. ' \
        "-i credentials-resource=#{@credentials_dir} " \
        "-i additional-resource=#{@additional_resource} " \
        "-o generated-files=#{@generated_files} ",
                        'YML_TEMPLATE_DIR' => 'additional-resource',
                        'SPRUCE_FILE_BASE_PATH' => 'credentials-resource',
                        'YML_FILES' => "'./credentials-resource/custom_dir/subdir/meta.yml ./credentials-resource/secrets.yml'",
                        'SUFFIX' => '')
    end

    after(:context) do
      FileUtils.rm_rf @generated_files
      FileUtils.rm_rf @credentials_dir
      FileUtils.rm_rf @additional_resource
    end

    it 'processes dummy template' do
      expected_filename = File.join(@generated_files, 'dummy.yml')
      expect(File).to exist(expected_filename)
    end

    it 'displays warning about missing files' do
      expect(@output).to include('WARNING: ./credentials-resource/custom_dir/subdir/meta.yml does not exist, generating an empty yaml file').and \
        include('WARNING: ./credentials-resource/secrets.yml does not exist, generating an empty yaml file')
    end

    it 'successes' do
      expect(@output).to end_with("succeeded\n")
    end
  end
end
