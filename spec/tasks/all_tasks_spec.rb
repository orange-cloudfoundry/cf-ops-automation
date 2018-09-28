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
        docker_image = task['image_resource']['source']['repository'].to_s
        docker_image = "library/#{docker_image}" unless docker_image.include?('/')
        docker_image_tag = task['image_resource']['source']['tag'] || 'latest'
        name = "#{docker_image}:#{docker_image_tag}"
        if images[name]
          images[name] = images[name]<< task_filename
        else
          images[name] = [task_filename]
        end
      end
      images
    end

    it 'ensures some tasks exist' do
      expect(tasks).not_to be_empty
    end

    it 'uses an existing image on docker hub'do
      # tasks.each do |task_filename|
      #   puts "processing #{task_filename}"
      #   task = YAML.load_file (task_filename)
      #   docker_image = task['image_resource']['source']['repository'].to_s
      #   docker_image = "library/#{docker_image}" unless docker_image.include?('/')
      #   docker_image_tag = task['image_resource']['source']['tag']|| 'latest'
      #   puts "searching for #{docker_image}:#{docker_image_tag}"
      #   manifest = docker_registry.manifest(docker_image, docker_image_tag)
      #   expect(manifest).not_to be_empty
      # end
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
