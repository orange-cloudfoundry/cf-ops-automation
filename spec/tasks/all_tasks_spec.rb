require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative './task_spec_helper'

describe 'all tasks' do
  context 'Pre-requisite' do
    let(:tasks_dir) { 'concourse/tasks/' }
    let(:tasks) { Dir.glob(tasks_dir + '**/*.yml') }
    let(:docker_images_with_task) do
      images = {}
      tasks.each do |task_filename|
        puts "processing file #{task_filename}"
        task = YAML.load_file task_filename
        docker_image = task.dig('image_resource', 'source', 'repository').to_s
        if docker_image.empty?
          puts "No image detected, ignoring #{task_filename}"
          next
        end
        docker_image = "library/#{docker_image}" unless docker_image.include?('/')
        docker_image_no_prefix = docker_image.delete_prefix(DOCKER_REGISTRY_PREFIX)
        docker_image_tag = task.dig('image_resource', 'source', 'tag') || 'latest'
        name = "#{docker_image_no_prefix}:#{docker_image_tag}"
        images[name] = if images[name]
                         images[name] << task_filename
                       else
                         [task_filename]
                        end
      end
      images
    end
    let(:expected_task_images) do
      [
        TaskSpecHelper.curl_image + ':' + TaskSpecHelper.curl_image_version,
        TaskSpecHelper.git_image + ':' + TaskSpecHelper.git_image_version,
        TaskSpecHelper.bosh_cli_v2_image + ':' + TaskSpecHelper.bosh_cli_v2_image_version,
        TaskSpecHelper.cf_cli_image + ':' + TaskSpecHelper.cf_cli_image_version,
        TaskSpecHelper.spruce_image + ':' + TaskSpecHelper.spruce_image_version,
        TaskSpecHelper.ruby_image + ':' + TaskSpecHelper.ruby_image_version,
        TaskSpecHelper.ruby_image + ':' + TaskSpecHelper.ruby_slim_image_version,
        "orangecloudfoundry/cf-ops-automation:latest",
        TaskSpecHelper.pre_deploy_image + ':' + TaskSpecHelper.pre_deploy_image_version,
        TaskSpecHelper.terraform_image + ':' + TaskSpecHelper.terraform_image_version
      ]
    end

    it 'ensures some tasks exists' do
      expect(tasks).not_to be_empty
    end

    it 'ensures tasks' do
      puts docker_images_with_task.keys.sort
      expect(docker_images_with_task.keys).to match_array(expected_task_images)
    end

    it 'ensures image resource use custom docker registry' do
      invalid_tasks = {}
      tasks.each do |task_filename|
        task = YAML.load_file task_filename
        docker_image = task.dig('image_resource', 'source', 'repository').to_s
        next if docker_image.empty?

        invalid_tasks[task_filename] = docker_image unless docker_image.start_with?(DOCKER_REGISTRY_PREFIX)
      end
      expect(invalid_tasks).to be_empty
    end

    it 'uses an existing image on docker hub' do
      docker_images_with_task.each do |image, files|
        puts "processing image #{image}"
        parsed_image = image.split(':')
        docker_image = parsed_image[0]
        docker_image_tag = parsed_image[1]
        puts "searching for #{docker_image}:#{docker_image_tag}"
        begin
          manifest = docker_registry.manifest(docker_image, docker_image_tag)
          expect(manifest).not_to be_empty
        rescue DockerRegistry2::NotFound => e
          raise DockerRegistry2::NotFound, " #{image} used by #{files}"
        end
      end
    end
  end
end
