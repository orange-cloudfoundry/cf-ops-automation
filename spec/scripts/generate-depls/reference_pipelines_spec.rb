require 'spec_helper'
require 'tmpdir'
require 'yaml'

describe 'reference concourse pipelines spec' do
  context 'resource_type exists' do
    let(:pipelines_dir) { File.join(File.dirname(__FILE__), 'fixtures/references') }
    let(:pipeline_files) { Dir.glob(pipelines_dir + '**/*.yml') }
    let(:resource_types) do
      result = []
      puts "list: #{pipeline_files}"
      pipeline_files.each do |pipeline_filename|
        puts "processing file #{pipeline_filename}"
        pipeline = YAML.load_file(pipeline_filename, aliases: true)
        result.concat(pipeline['resource_types']) if pipeline['resource_types']
      end
      result.uniq
    end
    let(:docker_images_from_resource_type) do
      images = {}
      resource_types.each do |resource_type|
        puts "processing resource #{resource_type}"
        resource_type_name = resource_type['name']
        docker_image_raw = resource_type['source']['repository'].to_s
        docker_image = docker_image_raw.delete_prefix(DOCKER_REGISTRY_PREFIX)
        docker_image = "library/#{docker_image}" unless docker_image.include?('/')
        docker_image_tag = resource_type['source']['tag'] || 'latest'
        name = "#{docker_image}:#{docker_image_tag}"
        images[name] = if images[name]
                         images[name] << resource_type_name
                       else
                         [resource_type_name]
                       end
      end
      images
    end

    it 'founds resource_type' do
      expect(resource_types).not_to be_empty
    end

    it 'uses an existing image on docker hub'do
      docker_images_from_resource_type.each do |image, files|
        puts "processing image #{image}"
        parsed_image = image.split(':')
        docker_image = parsed_image[0]
        docker_image_tag = parsed_image[1]
        puts "searching for #{docker_image}:#{docker_image_tag}"
        begin
          # RestClient.log = STDOUT # uncomment to enable rest client output
          manifest = docker_registry.manifest(docker_image, docker_image_tag)
          expect(manifest).not_to be_empty
          rescue DockerRegistry2::NotFound => not_found
            raise DockerRegistry2::NotFound, " #{image} used by #{files} from #{docker_registry_url}"
        end
      end
    end

  end
end
