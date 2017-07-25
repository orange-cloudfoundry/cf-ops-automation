require 'rspec'
require_relative '../../lib/template_processor'

describe TemplateProcessor do
  subject { described_class.new root_deployment_name, config, context }

  let(:root_deployment_name) { 'my_depls' }
  let(:config) { { dump_output: true, output_path: '/tmp' } }
  let(:context) { {'my_item' => 'good'} }

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
      subject {described_class.new 98_654}

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
      let(:test_pipeline_name) { './my-template-pipeline.yml.erb' }
      let(:pipelines_dir) { File.join('pipelines', 'template') }

      let(:my_yaml_erb_file) {
        {
            'resource_types' => [
              {  'name' => 'slack-notification',
               'type'=> 'docker-image'},
              'source'=> {  'repository' => 'cfcommunity/slack-notification-resource'  }
            ],
            'resources' => [],
            'jobs' => [
                {  'name' => '<%= my_item %>'  }
            ]
        }.to_yaml
      }

      before do
        allow(Dir).to receive(:[]).and_return([test_pipeline_name.to_s])
        allow(File).to receive(:read).and_return(my_yaml_erb_file)
      end

      after { FileUtils.rm_rf(File.join('tmp', 'pipelines')) }

      context 'process an erb file without context' do
        subject { described_class.new root_deployment_name }

        it 'raises an exception' do
          expect(Dir).to receive(:[]).with(pipelines_dir)
          expect(File).to receive(:read).with(test_pipeline_name)

          expect {subject.process(pipelines_dir)}.to raise_error(NameError, /undefined local variable or method `my_item/)
        end
      end

      context 'process an erb file with a context' do
        subject {described_class.new(root_deployment_name, config, context)}

        it 'generate a valid yaml file' do
          expect(Dir).to receive(:[]).with(pipelines_dir)
          expect(File).to receive(:read).with(test_pipeline_name)

          count=subject.process(pipelines_dir)
          expect(count).to eq(1)
        end
      end

      context 'process an invalid yml erb file with a context' do
        let(:invalid_yaml_erb_file){<<~TEST
                                    ---
                                    resource_types:
                                    -name= slack-notification
                                    type: docker-image
                                    - source:
                                        repository: cfcommunity/slack-notification-resource
                                    resources: []
                                    jobs:
                                        - name: "not good"
                                    TEST
        }

        before do
          allow(Dir).to receive(:[]).and_return([test_pipeline_name.to_s])
          allow(File).to receive(:read).and_return(invalid_yaml_erb_file)
        end
        it 'raise an exception' do
          expect {subject.process(pipelines_dir)}.to raise_error(Psych::SyntaxError, /could not find expected ':'/)
        end
      end

    end
  end

end
