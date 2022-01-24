require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../tasks/task_spec_helper'

describe 'static concourse pipelines spec' do
  let(:pipelines_dir) { 'concourse/pipelines/' }
  let(:pipelines_references_fixture) { 'spec/scripts/generate-depls/fixtures/references/' }
  let(:pipelines_references_dataset) { 'docs/reference_dataset/pipelines/' }
  let(:pipeline_files) do
    Dir.glob("#{pipelines_dir}**/*.yml") + Dir.glob("#{pipelines_references_fixture}*.yml") + Dir.glob("#{pipelines_references_dataset}*.yml")
  end

  context 'when checking pipelines definition' do
    let(:pipelines_without_reference_dataset) { Dir.glob("#{pipelines_dir}**/*.yml") + Dir.glob("#{pipelines_references_fixture}*.yml") }
    let(:pipelines_display) do
      result = []
      pipelines_without_reference_dataset.each do |pipeline_filename|
        pipeline = YAML.load_file(pipeline_filename)
        result << if pipeline['display']
                    pipeline['display'].to_yaml
                  else
                    "missing display in #{pipeline_filename}"
                  end
      end
      result.uniq
    end

    it 'has uniq background_display set' do
      expect(pipelines_display).to match_array("---\nbackground_image: \"((background-image-url))\"\n")
    end
  end

  context 'when resource_type exists' do
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

    it 'ensures docker-image resource-type use custom docker registry' do
      invalid_resource_type = []
      resource_types.select {|resource_type| resource_type.dig('type') == 'docker-image' }.each do |resource_type|
        docker_image_raw = resource_type['source']['repository'].to_s
        invalid_resource_type << docker_image_raw unless docker_image_raw.start_with?(DOCKER_REGISTRY_PREFIX)
      end

      expect(invalid_resource_type).to be_empty
    end

    it 'ensures registry-image resource-type does not override docker registry' do
      invalid_resource_type = []
      resource_types.select {|resource_type| resource_type.dig('type') == 'registry-image' }.each do |resource_type|
        docker_image_raw = resource_type['source']['repository'].to_s
        invalid_resource_type << docker_image_raw if docker_image_raw.start_with?(DOCKER_REGISTRY_PREFIX)
      end

      expect(invalid_resource_type).to be_empty
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
      [
       { "repository" => TaskSpecHelper.ruby_image, "tag" => TaskSpecHelper.ruby_image_version },
       { "repository" => TaskSpecHelper.ruby_image, "tag" => TaskSpecHelper.ruby_slim_image_version },
       { "repository" => TaskSpecHelper.alpine_image, "tag" => TaskSpecHelper.alpine_image_version },
       { "repository" => TaskSpecHelper.curl_image, "tag" => TaskSpecHelper.curl_image_version },
       { "repository" => TaskSpecHelper.git_image, "tag" => TaskSpecHelper.git_image_version },
       { "repository" => TaskSpecHelper.bosh_cli_v2_image, "tag" => TaskSpecHelper.bosh_cli_v2_image_version },
       { "repository" => TaskSpecHelper.bosh_cf_cli_image, "tag" => TaskSpecHelper.bosh_cf_cli_image_version },
       { "repository" => TaskSpecHelper.fly_image, "tag" => TaskSpecHelper.fly_image_version }
      ]
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
        result += source.uniq if source
        puts "#{pipeline_filename} adding #{source}"
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
