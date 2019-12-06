require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative './task_spec_helper'

describe 'all tasks' do
  context 'Pre-requisite' do
    let(:tasks_dir) { 'concourse/tasks/'}
    let(:tasks) { Dir.glob(tasks_dir + '**/*.yml') }
    let(:docker_images_with_task) do
      images = {}
      tasks.each do |task_filename|
        puts "processing file #{task_filename}"
        task = YAML.load_file (task_filename)
        docker_image = task['image_resource']&.fetch('source', [])&.fetch('repository', []).to_s
        if docker_image.empty?
          puts "No image detected, ignoring #{task_filename}"
          next
        end
        docker_image = "library/#{docker_image}" unless docker_image.include?('/')
        docker_image_no_prefix = docker_image.delete_prefix(DOCKER_REGISTRY_PREFIX)
        docker_image_tag = task.dig('image_resource','source','tag') || 'latest'
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
        "concourse/buildroot:curl",
        "concourse/busyboxplus:git",
        TaskSpecHelper.bosh_cli_v2_image + ':' + TaskSpecHelper.bosh_cli_v2_image_version,
        TaskSpecHelper.cf_cli_image + ':' + TaskSpecHelper.cf_cli_image_version,
        TaskSpecHelper.spruce_image + ':' + TaskSpecHelper.spruce_image_version,
        TaskSpecHelper.ruby_image + ':' + TaskSpecHelper.ruby_image_version,
        TaskSpecHelper.ruby_image + ':' + TaskSpecHelper.ruby_slim_image_version,
        "orangecloudfoundry/cf-ops-automation:latest",
        "orangecloudfoundry/spiff:latest",
        TaskSpecHelper.terraform_image + ':' + TaskSpecHelper.terraform_image_version
      ]
    end

    it 'ensures some tasks exist' do
      expect(tasks).not_to be_empty
    end

    it 'ensures tasks' do
      puts docker_images_with_task.keys.sort
      expect(docker_images_with_task.keys).to match_array(expected_task_images)
    end

    # FIXME enable when network issue on COA_CI@FE are fixed
    xit 'uses an existing image on docker hub'do
      docker_images_with_task.each do |image, files|
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
end
