require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../task_spec_helper'

describe 'bosh_interpolate task' do
  context 'when missing required BOSH_YAML_FILE env var' do
    before(:context) do
      @bosh_inputs = Dir.mktmpdir
      @manifest_dir = Dir.mktmpdir
      @secrets = Dir.mktmpdir
      @result_dir = Dir.mktmpdir

      @output = execute('-c concourse/tasks/bosh_interpolate/task.yml ' \
        '-i scripts-resource=. ' \
        "-i secrets=#{@secrets} " \
        "-i bosh-inputs=#{@bosh_inputs} " \
        "-i manifest-dir=#{@manifest_dir} " \
        "-o result-dir=#{@result_dir} ")
    end

    after(:context) do
      FileUtils.rm_rf @bosh_inputs if File.exist?(@bosh_inputs)
      FileUtils.rm_rf @secrets if File.exist?(@secrets)
      FileUtils.rm_rf @result_dir if File.exist?(@result_dir)
      FileUtils.rm_rf @manifest_dir if File.exist?(@manifest_dir)
    end

    it 'displays an error message' do
      expect(@output).to include('ERROR: missing environment variable: BOSH_YAML_FILE')
    end
  end

  context 'when executed' do
    let(:bosh_interpolated_file) { File.join(@result_dir, 'interpolated-my_base_yaml_file.yml') }
    let(:bosh_interpolated_yaml) { YAML.load_file bosh_interpolated_file }
    let(:expected_yaml) { YAML.safe_load @expected_yaml_content }

    before(:context) do
      @bosh_inputs = Dir.mktmpdir
      @manifest_dir = Dir.mktmpdir
      @secrets = Dir.mktmpdir
      @result_dir = Dir.mktmpdir

      @bosh_yaml = <<~YAML
        simple-yaml:
            with:
              var: ((my-var-value))
        operator-test:
          to-be-replaced-using-an-operator: true
      YAML

      @vars_yaml = <<~YAML
        my-var-value: a-value
      YAML

      @operator_yaml = <<~YAML
        - type: replace
          path: /operator-test
          value:
            operator-applied: true
      YAML

      @expected_yaml_content = <<~YAML
        simple-yaml:
            with:
              var: a-value
        operator-test:
          operator-applied: true
      YAML

      File.open(File.join(@bosh_inputs, 'my-custom-vars.yml'), 'w') { |file| file.write(YAML.safe_load(@vars_yaml).to_yaml) }
      File.open(File.join(@bosh_inputs, 'my-custom-operators.yml'), 'w') { |file| file.write(YAML.safe_load(@operator_yaml).to_yaml) }
      File.open(File.join(@manifest_dir, 'my_base_yaml_file.yml'), 'w') { |file| file.write(YAML.safe_load(@bosh_yaml).to_yaml) }

      @output = execute('-c concourse/tasks/bosh_interpolate/task.yml ' \
            '-i scripts-resource=. ' \
            "-i secrets=#{@secrets} " \
            "-i bosh-inputs=#{@bosh_inputs} " \
            "-i manifest-dir=#{@manifest_dir} " \
            "-o result-dir=#{@result_dir} ", \
                        'BOSH_YAML_FILE' => 'my_base_yaml_file.yml')
    end

    after(:context) do
      FileUtils.rm_rf @bosh_inputs if File.exist?(@bosh_inputs)
      FileUtils.rm_rf @secrets if File.exist?(@secrets)
      FileUtils.rm_rf @result_dir if File.exist?(@result_dir)
      FileUtils.rm_rf @manifest_dir if File.exist?(@manifest_dir)
    end

    it 'generates a file as result' do
      expect(File).to exist(bosh_interpolated_file)
    end

    it 'generates a non empty file' do
      expect(bosh_interpolated_yaml).not_to be_empty
    end

    it 'generates a yaml file using bosh interpolate' do
      expect(bosh_interpolated_yaml).to include(expected_yaml)
    end

    it 'executes without error' do
      expect(@output).not_to include('Exit code 1')
    end
  end

  context 'Pre-requisite' do
    let(:task) { YAML.load_file 'concourse/tasks/bosh_interpolate/task.yml' }

    it 'uses alphagov bosh-cli-v2 image' do
      docker_image_used = task['image_resource']['source']['repository'].to_s
      expect(docker_image_used).to match(TaskSpecHelper.bosh_cli_v2_image)
    end

    it 'uses a managed bosh-cli-v2 image version' do
      docker_image_tag_used = task['image_resource']['source']['tag'].to_s
      expect(docker_image_tag_used).to match(TaskSpecHelper.bosh_cli_v2_image_version)
    end
  end
end
