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

require 'yaml'
require 'fileutils'
require 'open3'
require 'open-uri'

# This class process boshrelease repackaging errors and try to get releases from bosh.io or github
class RepackageReleasesFallback
  BOSH_IO_PREFIX = "https://bosh.io/d/github.com".freeze
  GITHUB_PREFIX = "https://github.com".freeze

  def initialize(repackaged_error_filepath = "")
    @repackaged_errors = if File.exist?(repackaged_error_filepath)
                           YAML.load_file(repackaged_error_filepath) || {}
                         else
                           {}
                         end
  end

  def has_errors?
    !@repackaged_errors.empty?
  end

  def process(repackaged_releases_fallback_path, repackaged_releases_path)
    errors = @repackaged_errors.dup
    fallback_fixes = {}
    init_fallback_dir_with_repackaged_dir(repackaged_releases_fallback_path, repackaged_releases_path)
    fallback_to_bosh_io(errors, fallback_fixes, repackaged_releases_fallback_path)
    fallback_to_github(errors, fallback_fixes, repackaged_releases_fallback_path)

    unless errors.empty?
      File.open(File.join(repackaged_releases_fallback_path, 'fallback-errors.yml'), 'w+') { |file| file.write(YAML.dump(errors)) }
      raise errors.to_s
    end
    File.open(File.join(repackaged_releases_fallback_path, 'fallback-fixes.yml'), 'w+') { |file| file.write(YAML.dump(fallback_fixes)) } unless fallback_fixes.empty?
  end

  private

  def fallback_to_bosh_io(errors, fallback_fixes, repackaged_releases_fallback_path)
    successfully_processed = []
    @repackaged_errors.each do |name, details|
      puts "Failed to repackage #{name} boshrelease, trying direct download from bosh.io"
      begin
        download_from_bosh_io(name, details, repackaged_releases_fallback_path)
        update_errors_and_warnings(errors, fallback_fixes, name, successfully_processed)
      rescue RepackageFallbackError => e
        puts "Error detected while processing #{name}: #{e}"
        error_details = errors[name]
        error_details['bosh_io_error'] = e.to_s
        errors.store(name, error_details)
      end
    end
    generate_boshrelease_namespaces(repackaged_releases_fallback_path, successfully_processed)
  end

  def fallback_to_github(errors, fallback_fixes, repackaged_releases_fallback_path)
    successfully_processed = []
    remaining_errors = errors.dup
    remaining_errors.each do |name, details|
      puts "Failed to repackage #{name} boshrelease, trying direct download from github release"
      begin
        download_from_github(name, details, repackaged_releases_fallback_path)
        update_errors_and_warnings(errors, fallback_fixes, name, successfully_processed)
      rescue RepackageFallbackError => e
        puts "Error detected while processing #{name}: #{e}"
        error_details = errors[name]
        error_details['github_error'] = e.to_s
        errors.store(name, error_details)
      end
    end
    generate_boshrelease_namespaces(repackaged_releases_fallback_path, successfully_processed)
  end

  def init_fallback_dir_with_repackaged_dir(target, origin)
    FileUtils.cp_r(Dir[File.join(origin, '*.tgz')], target)
    FileUtils.cp_r(Dir[File.join(origin, 'boshreleases-namespaces.csv')], target)
  end

  def update_errors_and_warnings(errors, fallback_fixes, name, successfully_processed)
    repackage_error = errors.delete(name)
    fallback_fixes[name] = repackage_error
    successfully_processed << name
  end

  def download_from_github(name, details, repackaged_releases_fallback_path)
    boshrelease_filename, url = create_github_download_info(name, details)
    download_path = "#{repackaged_releases_fallback_path}/#{boshrelease_filename}"
    download_boshrelease(url, boshrelease_filename, download_path)
  end

  def download_boshrelease(url, boshrelease_filename, download_path, max_retry = 3)
    retries ||= 0
    puts "Start downloading #{boshrelease_filename} from #{url}"
    begin
      download(url, download_path)
    rescue Net::ReadTimeout => e
      puts "Retrying (#{retries += 1}/#{max_retry}: #{e.class}) downloading #{boshrelease_filename} from #{url}"
      retry if retries < max_retry
      File.delete(download_path) if File.exist?(download_path)
      raise RepackageFallbackError, e
    rescue StandardError => e
      File.delete(download_path) if File.exist?(download_path)
      raise RepackageFallbackError, e
    end
    puts "Downloaded #{boshrelease_filename} from #{url}"
  end

  def download_from_bosh_io(name, details, repackaged_releases_fallback_path)
    boshrelease_filename, url = create_bosh_io_download_info(name, details)
    download_path = "#{repackaged_releases_fallback_path}/#{boshrelease_filename}"
    download_boshrelease(url, boshrelease_filename, download_path)
  end

  def download(url, download_path)
    File.open(download_path, "wb") do |downloaded_file|
      # the following "open" is provided by open-uri
      URI.open(url, "rb") do |read_file|
        downloaded_file.write(read_file.read)
      end
    end
  end

  def create_github_download_info(name, details)
    repo = details['repository'] || ""
    version = details['version']
    tag_prefix = details['tag_prefix']
    url = "#{GITHUB_PREFIX}/#{repo}/releases/download/#{tag_prefix}#{version}/#{name}-#{version}.tgz"
    puts "trying to download release #{name} from #{url}"
    boshrelease_filename = "#{name}-#{version}.tgz"
    [boshrelease_filename, url]
  end

  def create_bosh_io_download_info(name, details)
    repo = details['repository'] || ""
    version = details['version']
    url = "#{BOSH_IO_PREFIX}/#{repo}?v=#{version}"
    puts "trying to download release #{name} from #{url}"
    boshrelease_filename = "#{name}-#{version}.tgz"
    [boshrelease_filename, url]
  end

  def generate_boshrelease_namespaces(repackaged_releases_path, successfully_processed)
    File.open(File.join(repackaged_releases_path, 'boshreleases-namespaces.csv'), 'a') do |file|
      successfully_processed.each do |name|
        version = @repackaged_errors&.dig(name, 'version')
        release_details = @repackaged_errors&.dig(name, 'repository')
        unless release_details && version
          puts "WARNING - Repackaged - Ignoring invalid release (#{name} defined in 'root_deployment.yml': missing 'repository' (#{release_details}) or 'version' (#{version})"
          next
        end
        namespace = release_details.split('/').first
        namespace_reference = "#{name}-#{version},#{namespace}\n"
        file.write(namespace_reference)
      end
    end
  end
end

class RepackageFallbackError < RuntimeError; end
