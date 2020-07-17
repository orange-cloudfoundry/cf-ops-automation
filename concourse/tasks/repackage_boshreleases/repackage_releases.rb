#
# Copyright (C) 2015-2020 Orange
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'json'
require 'fileutils'
require 'open3'
# This class repackage boshreleases from their git repositories
class RepackageReleases
  def initialize(root_deployment, missing_s3_releases = {}, list_releases = Tasks::Bosh::ListReleases.new, create_release = Tasks::Bosh::CreateRelease.new)
    raise "Invalid root_deployment object" unless root_deployment.respond_to?(:release_version) && root_deployment.respond_to?(:releases_git_urls) && root_deployment.respond_to?(:release)

    @root_deployment = root_deployment
    @list_releases_command_holder = list_releases
    @create_release_command_holder = create_release
    @missing_s3_releases = missing_s3_releases
  end

  def process(repackaged_releases_path, base_git_clones_path, logs_path)
    errors = {}
    successfully_processed = []
    begin
      releases_not_uploaded_to_director = filter_releases
    rescue Tasks::Bosh::BoshCliError, Resolv::ResolvError => e
      puts "Error detected while filtering bosh director releases"
      errors.store("Bosh director", e)
      releases_not_uploaded_to_director = {}
    end
    releases_not_uploaded_to_director.each do |name, git_url|
      puts "Processing #{name} boshrelease from #{git_url}"
      begin
        git_clone_path = clone_git_repository(name, git_url, base_git_clones_path, logs_path)
        git_checkout_branch(name, git_clone_path)
        repackage_release(name, repackaged_releases_path, git_clone_path, logs_path)
        clean_bosh_files(logs_path)
        clean_git_clone(git_clone_path, logs_path)
        successfully_processed << name
      rescue CloneError, Tasks::Bosh::BoshCliError => e
        puts "Error detected while processing #{name}"
        errors.store(name, e)
      end
    end
    generate_boshrelease_namespaces(repackaged_releases_path, successfully_processed)

    unless errors.empty?
      File.open(File.join(repackaged_releases_path, 'errors.yml'), 'w+') { |file| file.write(YAML.dump(errors)) }
      raise errors.to_s
    end
  end

  private

  def generate_boshrelease_namespaces(repackaged_releases_path, successfully_processed)
    File.open(File.join(repackaged_releases_path, 'boshreleases-namespaces.csv'), 'w+') do |file|
      successfully_processed.each do |name|
        version = @root_deployment.release_version(name)
        release_details = @root_deployment.release(name)&.dig('repository')
        unless release_details
          puts "WARNING - Repackaged - Ignoring invalid release (#{name} defined in 'root_deployemnt.yml': missing 'repository'"
          next
        end
        namespace = release_details.split('/').first
        namespace_reference = "#{name}-#{version},#{namespace}\n"
        file.write(namespace_reference)
      end
    end
  end

  def clean_git_clone(git_clone_path, logs_path)
    raise "Invalid git_clone_path: #{git_clone_path}" if git_clone_path.to_s.empty? || git_clone_path == '/' || git_clone_path == '*'

    puts "Clean git files"
    FileUtils.rm_rf(git_clone_path)
  end

  def repackage_release(name, destination_dir, working_dir, logs_path)
    version = @root_deployment.release_version(name)
    raise "ERROR: not version found for #{name}" unless version

    puts "Preparing #{name}:#{version} create release at #{destination_dir}"
    @create_release_command_holder.execute(name: name, version: version, tarball_path: destination_dir, dir: working_dir)
  end

  def clean_bosh_files(logs_path)
    puts "Clean bosh files"
    FileUtils.rm_rf("~/.bosh/tmp")
  end

  def clone_git_repository(boshrelease_name, git_url, base_git_clones_path, logs_path)
    git_clone_path = File.join(base_git_clones_path, boshrelease_name)
    error_message = ""
    status = nil
    cmd_line = "git clone \"#{git_url}\" \"#{git_clone_path}\""
    Open3.popen2e(cmd_line.to_s) do |_, stdout_stderr, wait_thr|
      while line = stdout_stderr.gets
        puts(line)
        error_message += line
      end
      status = wait_thr.value
      error_message += "Failed to clone '#{boshrelease_name}' from '#{git_url}'" unless status.success?
    end
    raise CloneError, error_message unless status&.success? && Dir.exist?(git_clone_path)

    git_clone_path
  end

  def git_checkout_branch(boshrelease_name, git_clone_path)
    if @root_deployment.release_skip_branch_checkout(boshrelease_name)
      puts "Skipping branch checkout for #{boshrelease_name}. Disable 'skip_branch_checkout' to switch it off"
      return
    end

    git_tag_name = "#{@root_deployment.release_tag_prefix(boshrelease_name)}#{@root_deployment.release_version(boshrelease_name)}"
    puts "Checkout #{git_tag_name}"
    cmd_line = "cd #{git_clone_path} && git checkout #{git_tag_name}"
    stdout_and_stderr, status = Open3.capture2(cmd_line)
    puts stdout_and_stderr
    raise CloneError, "Ensure #{git_tag_name} exist, "+ stdout_and_stderr.to_s unless status&.success?
  end

  def filter_releases
    active_releases = @list_releases_command_holder.execute
    puts "Filtering releases"
    boshreleases_git_urls = @root_deployment.releases_git_urls
    boshreleases_git_urls.delete_if do |name, _url|
      target_version = @root_deployment.release_version(name).to_s
      version_details = active_releases.dig(name, target_version)
      bosh_uploaded = version_details.nil? ? false : true
      s3_uploaded = !missing_boshrelease?(name, target_version)
      already_deployed = bosh_uploaded && s3_uploaded
      puts "Release #{name} upload status, bosh director: #{bosh_uploaded} - S3: #{s3_uploaded}"
      puts "Skipping #{name}, version #{target_version} already deployed" if already_deployed
      already_deployed
    end
  end

  def missing_boshrelease?(name, target_version)
    v = @missing_s3_releases.dig(name, 'version').to_s
    return v == target_version.to_s
  end

end

class CloneError < RuntimeError; end
