require 'rspec'
require 'fileutils'

require_relative '../../lib/template_processor'

describe TemplateProcessor do
  let(:root_deployment_name) { 'my_depls' }
  let(:context) { { 'my_item' => 'good' } }

  describe '#initialize' do
    context 'the root_deployment_name is nil' do
      subject { described_class.new nil }

      it 'raises an exception' do
        expect {subject}.to raise_error(RuntimeError)
      end
    end

    context 'the config is nil' do
      subject { described_class.new(root_deployment_name, nil) }

      it 'raises an exception' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'the root_deployment_name is empty' do
      subject { described_class.new '' }

      it 'raises an exception' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'the root_deployment_name is not a string' do
      subject { described_class.new 98_654 }

      it 'raises an exception' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

  end

  describe '#process' do
    context 'when no parameter are provided' do
      subject { described_class.new(root_deployment_name) }

      it 'supports nil' do
        count = subject.process nil
        expect(count).to eq(0)
      end

      it 'supports empty string' do
        count = subject.process ''
        expect(count).to eq(0)
      end
    end

    context 'with valid parameter' do
      subject { described_class.new root_deployment_name, config, context }

      # output_dir= File.join('/tmp', 'pipelines')
      before(:context) do
        @output_dir = Dir.mktmpdir('generated-pipelines')
        @pipelines_output_dir = File.join(@output_dir, 'pipelines')
        @template_pipeline_name = 'my-template-pipeline.yml.erb'
        @pipelines_dir = Dir.mktmpdir('pipeline-templates')

      end


      let(:config) { { dump_output: true, output_path: @output_dir } }
      let(:yaml_erb_file_content) {
        {
          'resource_types' => [
            {  'name' => 'slack-notification',
               'type' => 'docker-image',
               'source' => { 'repository' => 'cfcommunity/slack-notification-resource' }
            }
          ],
          'resources' => [],
          'jobs' => [
            {  'name' => "<%= my_item %>" }
          ]
        }.to_yaml
      }

      before do
        File.open(File.join(@pipelines_dir,@template_pipeline_name), 'w') { |file| file.write(yaml_erb_file_content) }
      end

      context 'process an erb file without context' do
        subject { described_class.new root_deployment_name }

        # before do
        #   allow(Dir).to receive(:[]).and_return([@template_pipeline_name.to_s])
        #   allow(File).to receive(:read).and_call_original
        #   allow(File).to receive(:read).with(@template_pipeline_name).and_return(yaml_erb_file_content)
        # end

        after(:context) { FileUtils.rm_rf(@output_dir) }

        xit 'raises an exception' do
          expect(Dir).to receive(:[]).with(@pipelines_dir)
          expect(File).to receive(:read).with(@template_pipeline_name)

          expect { subject.process(@pipelines_dir) }.to raise_error(NameError, /undefined local variable or method `my_item/)
        end
      end

      context 'process an erb file' do
        subject { described_class.new(root_deployment_name, config, context) }

        let(:expected_yaml_file){<<~TEST
                                    ---
                                    resource_types:
                                    - name: slack-notification
                                      type: docker-image
                                      source:
                                        repository: cfcommunity/slack-notification-resource
                                    resources: []
                                    jobs:
                                    - name: "good"
                                  TEST
        }


        before {@count=subject.process(@pipelines_dir + '/*') }

        # before do
        #   allow(Dir).to receive(:[]).and_return([@template_pipeline_name.to_s])
        #   allow(File).to receive(:read).and_call_original
        #   allow(File).to receive(:read).with(@template_pipeline_name).and_return(yaml_erb_file_content)
        # end

        after(:context) {
          FileUtils.rm_rf(@output_dir)
          FileUtils.rm_rf(@pipelines_dir)
        }

        xit 'generate a valid yaml file' do
          expect(Dir).to receive(:[]).with(@pipelines_dir)
          expect(File).to receive(:read).with(File.join(@pipelines_output_dir, @template_pipeline_name))

          expect(@count).to eq(1)
          expect(File.read(File.join(@pipelines_output_dir, @template_pipeline_name))).to eq(expected_yaml_file)
        end

        xit 'generated filename is correct' do
          expect(File.exist?(File.join(@pipelines_output_dir, @template_pipeline_name))).to be_truthy
        end


      end

      context 'process an invalid yml erb file' do
        let(:invalid_yaml_erb_file){<<~TEST
                                    ---
                                    resource_types:
                                    -name= slack-notification
                                    jobs:
                                        - name: "not good or <%= my_item %>"
                                    TEST
        }
        let(:expected_yaml_file){<<~TEST
                                    ---
                                    resource_types:
                                    -name= slack-notification
                                    jobs:
                                        - name: "not good or good"
                                   TEST
        }

        # before do
        #   allow(Dir).to receive(:[]).and_return([@template_pipeline_name.to_s])
        #   allow(File).to receive(:read).and_call_original
        #   allow(File).to receive(:read).with(@template_pipeline_name).and_return(invalid_yaml_erb_file)
        # end

        after(:context) { FileUtils.rm_rf(@output_dir) }

        xit 'raise an exception' do
          expect{ subject.process(@pipelines_dir) }.to raise_error(Psych::SyntaxError, /could not find expected ':'/)
          expect(File.exist?(File.join(@pipelines_output_dir, 'my_depls-my-template-generated.yml'))).to be_truthy

        end

        xit 'generated filename is correct' do
          expect(File.exist?(File.join(@pipelines_output_dir, 'my_depls-my-template-generated.yml'))).to be_truthy
        end

        xit 'generated content is an invalid yaml file' do
          expect(File.read(File.join(@pipelines_output_dir, 'my_depls-my-template-generated.yml'))).to eq(expected_yaml_file)
        end
      end

    end
  end

end
