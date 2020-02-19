
# require 'spec_helper.rb'
require 'yaml'
require 'tmpdir'
require 'fileutils'

describe 'generate_manifest task' do
  let(:credentials_meta_content) { { "meta" => { "ntp" => { "version" => 12 } } } }

  context 'when no template are detected' do
    after(:context) do
      FileUtils.rm_rf @generated_files
    end

    before(:context) do
      @generated_files = Dir.mktmpdir

      @output = execute('-c concourse/tasks/generate_manifest/task.yml ' \
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

      @output = execute('-c concourse/tasks/generate_manifest/task.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        "-i additional-resource=#{@additional_resource} " \
        "-o generated-files=#{@generated_files} ",
                        'YML_TEMPLATE_DIR' => 'additional-resource/template',
                        'SPRUCE_FILE_BASE_PATH' => 'credentials-resource/',
                        'YML_FILES' => "'./credentials-resource/meta.yml ./credentials-resource/secrets.yml'",
                        'SUFFIX' => '')
    rescue FlyExecuteError => e
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
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
        @output = execute('-c concourse/tasks/generate_manifest/task.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        '-i additional-resource=spec/tasks/generate_manifest/additional-resource ' \
        "-o generated-files=#{@generated_files} ",
                          'YML_TEMPLATE_DIR' => 'additional-resource/invalid-template',
                          'SPRUCE_FILE_BASE_PATH' => 'credentials-resource/',
                          'YML_FILES' => "'./credentials-resource/meta.yml ./credentials-resource/secrets.yml'",
                          'SUFFIX' => '')
      rescue FlyExecuteError => e
        @output = e.out
        @fly_error = e.err
        @fly_status = e.status
      end

      after(:context) do
        FileUtils.rm_rf @generated_files
      end

      it 'display an error message' do
        expect(@output).to include('secrets.undefined_key').and \
          include('could not be found in the datastructure')
      end

      it 'returns with exit status 2' do
        expect(@fly_status.exitstatus).to eq(2)
      end
    end

    context 'when a post generate script is detected' do
      before(:context) do
        @output = execute('-c concourse/tasks/generate_manifest/task.yml ' \
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

      @output = execute('-c concourse/tasks/generate_manifest/task.yml ' \
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

    context 'when profiles are defined' do
      let(:expected_generated_iaas_filenames) { %w[iaas-operators.yml iaas.yml iaas-unspruced-vars.yml iaas-vars.yml].sort }
      let(:expected_generated_profile_a_filenames) { %w[iaas.yml profile-a-operators.yml profile-a.yml profile-b-unspruced-vars.yml].sort }
      let(:expected_generated_base_filenames) { %w[shared-operators.yml shared.yml shared-vars.yml] }
      let(:expected_generated_filenames) { (expected_generated_base_filenames + expected_generated_iaas_filenames + expected_generated_profile_a_filenames).sort.uniq}

      before(:context) do
        @generated_files = Dir.mktmpdir
        @additional_resource = File.join(File.dirname(__FILE__), 'additional-resource')

        @output = execute('-c concourse/tasks/generate_manifest/task.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        "-i additional-resource=#{@additional_resource} " \
        "-o generated-files=#{@generated_files} ",
                          'YML_TEMPLATE_DIR' => 'additional-resource/template-with-iaas',
                          'SPRUCE_FILE_BASE_PATH' => 'credentials-resource/',
                          'YML_FILES' => "'./credentials-resource/meta.yml ./credentials-resource/secrets.yml'",
                          'SUFFIX' => '',
                          'PROFILES' => 'profile-a',
                          'IAAS_TYPE' => 'openstack')
      end

      it 'processes iaas-type files before profiles' do
        expected_content = {}.merge(credentials_meta_content).merge('name' => 'profile-a', 'director_uuid' => '1234-4567-7898-7654-3210')
        loaded_yaml_content = YAML.load_file(File.join(@generated_files, 'iaas.yml'))
        expect(loaded_yaml_content).to eq(expected_content)
      end

      it 'processes only expected files' do
        processed_files = Dir[File.join(@generated_files,'*')].map { |path| File.basename(path) }.sort
        expect(processed_files).to eq(expected_generated_filenames)
      end
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

      @output = execute('-c concourse/tasks/generate_manifest/task.yml ' \
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
      expect(@output).to match("\nsucceeded\n")
    end
  end

  context 'when a link is broken' do
    after(:context) do
      FileUtils.rm_rf @generated_files
      FileUtils.rm_rf @additional_resource
    end

    before(:context) do
      @generated_files = Dir.mktmpdir
      @additional_resource = Dir.mktmpdir
      @additional_resource_reference = 'spec/tasks/generate_manifest/additional-resource'
      FileUtils.cp_r(@additional_resource_reference + '/.', @additional_resource)
      a_symlink = File.join(@additional_resource,"a-symlink-operators.yml")
      File.symlink('../dummy_symlink', a_symlink) unless File.symlink?(a_symlink)

      @output = execute('-c concourse/tasks/generate_manifest/task.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        "-i additional-resource=#{@additional_resource} " \
        "-o generated-files=#{@generated_files} ",
                        'IAAS_TYPE' => '',
                        'YML_TEMPLATE_DIR' => 'additional-resource',
                        'SPRUCE_FILE_BASE_PATH' => '',
                        'YML_FILES' => '',
                        'SUFFIX' => '')
    rescue FlyExecuteError => e
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
    end

    it 'displays an error message' do
      expect(@output).to include("cp: can't stat './a-symlink-operators.yml'")
    end

    it 'returns with exit status 1' do
      expect(@fly_status.exitstatus).to eq(1)
    end
  end

  context 'when profiles are defined with auto-sort' do
    let(:paas_template_path) { File.join(@additional_resource, 'template') }
    let(:profile_a_path) { File.join(paas_template_path, 'profile-a') }
    let(:profile_b_path) { File.join(paas_template_path, 'profile-b') }
    let(:base_tpl_yml_files) { Dir[File.join(paas_template_path, '*-tpl.yml')].sort }
    let(:profiles_tpl_yml_files) { (Dir[File.join(profile_a_path, '*-tpl.yml')] + Dir[File.join(profile_b_path, '*-tpl.yml')]).sort }
    let(:tpl_yml_files) { (base_tpl_yml_files + profiles_tpl_yml_files).sort }
    let(:generated_files_dir_content) { Dir[File.join(@generated_files, '*')] }
    let(:expected_generated_profile_b_filenames) { %w[profile-b.yml profile-b-unspruced-vars.yml second.yml profile-b-operators.yml].sort }
    let(:expected_generated_profile_a_filenames) { %w[first.yml profile-a.yml profile-b-unspruced-vars.yml second.yml profile-a-operators.yml].sort }
    let(:expected_generated_base_filenames) { %w[a-link-to-an-operators.yml an-operators.yml first.yml my-vars.yml second.yml unspruced-vars.yml] }
    let(:expected_generated_filenames) { (expected_generated_base_filenames + expected_generated_profile_a_filenames + expected_generated_profile_b_filenames).sort.uniq}


    before(:context) do
      @generated_files = Dir.mktmpdir
      @additional_resource = File.join(File.dirname(__FILE__), 'additional-resource')
      @fly_error = nil
      @fly_status = 0

      @output = execute('-c concourse/tasks/generate_manifest/task.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        "-i additional-resource=#{@additional_resource} " \
        "-o generated-files=#{@generated_files} ",
                        'YML_TEMPLATE_DIR' => 'additional-resource/template',
                        'SPRUCE_FILE_BASE_PATH' => 'credentials-resource/',
                        'YML_FILES' => "'./credentials-resource/meta.yml ./credentials-resource/secrets.yml'",
                        'PROFILES' => "'profile-b,profile-a'",
                        'SUFFIX' => '')
    rescue FlyExecuteError => e
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
    end

    after(:context) do
      FileUtils.rm_rf @generated_files
    end

    it 'does not generate an error message' do
      expect(@fly_error).to be nil
    end

    it 'processes profile-b files' do
      expected_generated_profile_b_filenames.each do |filename|
        generated_file_path = File.join(@generated_files, filename)
        expect(File.exist?(generated_file_path)).to be true
      end
    end

    it 'processes profile-a files' do
      expected_generated_profile_a_filenames.each do |filename|
        generated_file_path = File.join(@generated_files, filename)
        expect(File.exist?(generated_file_path)).to be true
      end
    end

    it 'generates a file per valid template' do
      tpl_yml_files .map { |filename| File.basename(filename, '-tpl.yml') }.each do |base_filename|
        expected_filename = File.join(@generated_files, base_filename + '.yml')
        expect(File).to exist(expected_filename), 'expected ' + base_filename + '.yml'
      end
    end

    it 'processes profiles in alphabetical order' do
      expected_content = {}.merge(credentials_meta_content).merge('name' => 'profile-b-second_deployment')
      loaded_yaml_content = YAML.load_file(File.join(@generated_files, 'second.yml'))
      expect(loaded_yaml_content).to eq(expected_content)
    end

    it 'overrides files processed by previous profile' do
      expected_content = { 'vars' => { 'profile-b' => { 'skip' => true } } }
      loaded_yaml_content = YAML.load_file(File.join(@generated_files, 'profile-b-unspruced-vars.yml'))
      expect(loaded_yaml_content).to eq(expected_content)
    end

    it 'processes only expected files' do
      processed_files = Dir[File.join(@generated_files,'*')].map { |path| File.basename(path) }.sort
      expect(processed_files).to eq(expected_generated_filenames)
    end

    context 'when processing an invalid template' do

      before(:context) do
        @generated_files = Dir.mktmpdir
        @additional_resource = File.join(File.dirname(__FILE__), 'additional-resource')
        @fly_error = nil
        @fly_status = 0

        @output = execute('-c concourse/tasks/generate_manifest/task.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        "-i additional-resource=#{@additional_resource} " \
        "-o generated-files=#{@generated_files} ",
                          'YML_TEMPLATE_DIR' => 'additional-resource',
                          'SPRUCE_FILE_BASE_PATH' => 'credentials-resource',
                          'YML_FILES' => "'./credentials-resource/meta.yml ./credentials-resource/secrets.yml'",
                          'PROFILES' => "'invalid-template'",
                          'SUFFIX' => '')
      rescue FlyExecuteError => e
        @output = e.out
        @fly_error = e.err
        @fly_status = e.status
      end

      after(:context) do
        FileUtils.rm_rf @generated_files
      end

      it 'display an error message' do
        expect(@output).to include('secrets.undefined_key').and \
          include('could not be found in the datastructure')
      end

      it 'returns with exit status 2' do
        expect(@fly_status.exitstatus).to eq(2)
      end
    end
  end

  context 'when profiles are defined without auto-sort' do
    let(:paas_template_path) { File.join(@additional_resource, 'template') }
    let(:profile_a_path) { File.join(paas_template_path, 'profile-a') }
    let(:profile_b_path) { File.join(paas_template_path, 'profile-b') }
    let(:base_tpl_yml_files) { Dir[File.join(paas_template_path, '*-tpl.yml')].sort }
    let(:profiles_tpl_yml_files) { (Dir[File.join(profile_a_path, '*-tpl.yml')] + Dir[File.join(profile_b_path, '*-tpl.yml')]).sort }
    let(:tpl_yml_files) { (base_tpl_yml_files + profiles_tpl_yml_files).sort }
    let(:generated_files_dir_content) { Dir[File.join(@generated_files, '*')] }
    let(:expected_generated_profile_b_filenames) { %w[first.yml profile-b.yml profile-b-unspruced-vars.yml second.yml profile-b-operators.yml].sort }
    let(:expected_generated_profile_a_filenames) { %w[first.yml profile-a.yml profile-b-unspruced-vars.yml profile-a-operators.yml].sort }
    let(:expected_generated_base_filenames) { %w[a-link-to-an-operators.yml an-operators.yml first.yml my-vars.yml second.yml unspruced-vars.yml] }
    let(:expected_generated_filenames) { (expected_generated_base_filenames + expected_generated_profile_a_filenames + expected_generated_profile_b_filenames).sort.uniq}


    before(:context) do
      @generated_files = Dir.mktmpdir
      @additional_resource = File.join(File.dirname(__FILE__), 'additional-resource')
      @fly_error = nil
      @fly_status = 0

      @output = execute('-c concourse/tasks/generate_manifest/task.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        "-i additional-resource=#{@additional_resource} " \
        "-o generated-files=#{@generated_files} ",
                        'YML_TEMPLATE_DIR' => 'additional-resource/template',
                        'SPRUCE_FILE_BASE_PATH' => 'credentials-resource/',
                        'YML_FILES' => "'./credentials-resource/meta.yml ./credentials-resource/secrets.yml'",
                        'PROFILES' => "'profile-b,profile-a'",
                        'PROFILES_AUTOSORT' => "false",
                        'SUFFIX' => '')
    rescue FlyExecuteError => e
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
    end

    after(:context) do
      FileUtils.rm_rf @generated_files
    end

    it 'does not generate an error message' do
      expect(@fly_error).to be nil
    end

    it 'processes profile-b files' do
      expected_generated_profile_b_filenames.each do |filename|
        generated_file_path = File.join(@generated_files, filename)
        expect(File.exist?(generated_file_path)).to be true
      end
    end

    it 'processes profile-a files' do
      expected_generated_profile_a_filenames.each do |filename|
        generated_file_path = File.join(@generated_files, filename)
        expect(File.exist?(generated_file_path)).to be true
      end
    end

    it 'generates a file per valid template' do
      tpl_yml_files .map { |filename| File.basename(filename, '-tpl.yml') }.each do |base_filename|
        expected_filename = File.join(@generated_files, base_filename + '.yml')
        expect(File).to exist(expected_filename), 'expected ' + base_filename + '.yml'
      end
    end

    it 'processes profiles in declared order' do
      expected_content = {}.merge(credentials_meta_content).merge('name' => 'profile-a')
      loaded_yaml_content = YAML.load_file(File.join(@generated_files, 'first.yml'))
      expect(loaded_yaml_content).to eq(expected_content)
    end

    it 'overrides files processed by previous profile' do
      expected_content = { 'vars' => { 'profile-a' => { 'skip' => true } } }
      loaded_yaml_content = YAML.load_file(File.join(@generated_files, 'profile-b-unspruced-vars.yml'))
      expect(loaded_yaml_content).to eq(expected_content)
    end

    it 'processes only expected files' do
      processed_files = Dir[File.join(@generated_files,'*')].map { |path| File.basename(path) }.sort
      expect(processed_files).to eq(expected_generated_filenames)
    end
  end

  context 'when bosh config files exist' do
    after(:context) do
      FileUtils.rm_rf @generated_files if Dir.exist?(@generated_files)
      FileUtils.rm_rf @additional_resource if Dir.exist?(@additional_resource)
    end

    before(:context) do
      @generated_files = Dir.mktmpdir
      @additional_resource = Dir.mktmpdir
      @additional_resource_reference = 'spec/tasks/generate_manifest/additional-resource'
      FileUtils.cp_r(@additional_resource_reference + '/.', @additional_resource)
      %w[cloud runtime cpi].each { |config_file| FileUtils.touch(File.join(@additional_resource, 'template', config_file + "-config.yml")) }

      @output = execute('-c concourse/tasks/generate_manifest/task.yml ' \
        '-i scripts-resource=. ' \
        '-i credentials-resource=spec/tasks/generate_manifest/credentials-resource ' \
        "-i additional-resource=#{@additional_resource} " \
        "-o generated-files=#{@generated_files} ",
                        'IAAS_TYPE' => '',
                        'YML_TEMPLATE_DIR' => 'additional-resource/template',
                        'SPRUCE_FILE_BASE_PATH' => 'credentials-resource/',
                        'YML_FILES' => "'./credentials-resource/meta.yml ./credentials-resource/secrets.yml'",
                        'SUFFIX' => '')
    rescue FlyExecuteError => e
      @output = e.out
      @fly_error = e.err
      @fly_status = e.status
    end

    it "handles [cloud|runtime|cpi]-confg.yml" do
      %w[cloud runtime cpi].each do |bosh_config_type|
        expected_filename = File.join(@generated_files, bosh_config_type + '-config.yml')
        expect(File).to exist(expected_filename)
      end
    end

    it 'processes others files also' do
      templates_files_processed_count = 6 # as 'another_file.yml' is ignored
      bosh_config_files_count = 3
      expected_files_count = templates_files_processed_count + bosh_config_files_count
      processed_files = Dir[File.join(@generated_files,'*')]
      expect(processed_files.size).to eq(expected_files_count), "expected #{processed_files.size} to equals #{expected_files_count} - Generated files : #{processed_files}"
    end
  end
end
