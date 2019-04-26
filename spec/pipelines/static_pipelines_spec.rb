require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../tasks/task_spec_helper'

describe 'static concourse pipelines spec' do
  let(:pipelines_dir) { 'concourse/pipelines/' }
  let(:pipelines_references_fixture) { 'spec/scripts/generate-depls/fixtures/references/' }
  let(:pipelines_references_dataset) { 'docs/reference_dataset/pipelines/' }
  let(:pipeline_files) do
    Dir.glob(pipelines_dir + '**/*.yml') + Dir.glob(pipelines_references_fixture + '*.yml') + Dir.glob(pipelines_references_dataset + '*.yml')
  end

   context 'resource_type exists' do
    let(:resource_types) do
      result = []
      puts "list: #{pipeline_files}"
      pipeline_files.each do |pipeline_filename|
        puts "processing file #{pipeline_filename}"
        pipeline = YAML.load_file(pipeline_filename)
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

    it 'uses an existing image on docker hub' do
      docker_images_from_resource_type.each do |image, files|
        puts "processing image #{image}"
        parsed_image = image.split(':')
        docker_image = parsed_image[0]
        docker_image_tag = parsed_image[1]
        puts "searching for #{docker_image}:#{docker_image_tag}"
        begin
          manifest = docker_registry.manifest(docker_image, docker_image_tag)
          expect(manifest).not_to be_empty
        rescue DockerRegistry2::NotFound => not_found
          raise DockerRegistry2::NotFound, " #{image} used by #{files.to_s}"
        end
      end
    end
  end

  context 'when job image_resources is defined' do
    let(:expected_task_images) do
      [{ "repository" => "concourse/busyboxplus", "tag" => "git" },
       { "repository" => TaskSpecHelper.ruby_image, "tag" => TaskSpecHelper.ruby_image_version },
       { "repository" => "orangecloudfoundry/orange-cf-bosh-cli" },
       { "repository" => TaskSpecHelper.ruby_image, "tag" => TaskSpecHelper.ruby_slim_image_version },
       { "repository" => TaskSpecHelper.terraform_image, "tag" => TaskSpecHelper.terraform_image_version },
       { "repository" => "alpine", "tag" => "3.5" },
       { "repository" => "governmentpaas/curl-ssl" },
       { "repository" => TaskSpecHelper.bosh_cli_v2_image, "tag" => TaskSpecHelper.bosh_cli_v2_image_version }]
    end
    let(:image_resources) do
      result = []
      puts "list: #{pipeline_files}"
      pipeline_files.each do |pipeline_filename|
        puts "processing file #{pipeline_filename}"
        pipeline = YAML.load_file(pipeline_filename)
        image_resources = pipeline['jobs']&.flat_map { |job| job['plan'] }&.compact&.flat_map { |config| config['config'] }&.compact&.flat_map { |image_resource| image_resource['image_resource'] }
        source = image_resources&.map { |job| job['source'] }
        source&.flat_map do |s|
          repo = s["repository"].delete_prefix(DOCKER_REGISTRY_PREFIX)
          s["repository"] = repo
          s
        end
        result.concat(source.uniq) if source
      end
      result.uniq
    end
    let(:docker_images_from_image_resource_jobs) do
      images = []
      image_resources.each do |image_resource|
        puts "processing task config #{image_resource}"
        docker_image_raw = image_resource['repository'].to_s
        docker_image = docker_image_raw.delete_prefix(DOCKER_REGISTRY_PREFIX)
        docker_image = "library/#{docker_image}" unless docker_image.include?('/')
        docker_image_tag = image_resource['tag'] || 'latest'
        name = "#{docker_image}:#{docker_image_tag}"
        images << name
      end
      images.sort
    end

    it 'matches expected images' do
      expect(image_resources).to match_array(expected_task_images)
    end

    it 'exists on docker hub' do
      docker_images_from_image_resource_jobs.each do |image|
        puts "processing image #{image}"
        parsed_image = image.split(':')
        docker_image = parsed_image.first
        docker_image_tag = parsed_image.last
        puts "searching for #{docker_image}:#{docker_image_tag}"
        begin
          manifest = docker_registry.manifest(docker_image, docker_image_tag)
          expect(manifest).not_to be_empty
        rescue DockerRegistry2::NotFound => not_found
          raise DockerRegistry2::NotFound, " #{image} not found"
        end
      end
    end
  end
end
