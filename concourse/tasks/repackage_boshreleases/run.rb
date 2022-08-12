#!/usr/bin/env ruby
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
require_relative './repackage_releases'
require_relative '../../../lib/tasks'

puts __FILE__
root_deployment_name = ENV['ROOT_DEPLOYMENT_NAME']
raise 'FATAL: Missing root deployment name' if root_deployment_name.to_s.empty?

templates_path = ENV['TEMPLATES_PATH']
raise 'FATAL: Missing templates_path' if templates_path.to_s.empty?

repackaged_releases_path = ENV['REPACKAGED_RELEASES_PATH']
raise 'FATAL: Missing repackaged_releases_path' if repackaged_releases_path.to_s.empty?

logs_path = ENV['LOGS_PATH']
raise 'FATAL: Missing logs_path' if logs_path.to_s.empty?

base_git_clones_path = ENV['BASE_GIT_CLONES_PATH']
raise 'FATAL: Missing base_git_clones_path' if base_git_clones_path.to_s.empty?

missing_s3_releases_filepath = ARGV[0]
missing_s3_releases = if File.exist?(missing_s3_releases_filepath)
                        YAML.load_file(missing_s3_releases_filepath, aliases: true) || {}
                      else
                        {}
                      end

root_deployment = Tasks::TemplatesRepo::RootDeployment.new(root_deployment_name, templates_path)
repackage_releases = RepackageReleases.new(root_deployment, missing_s3_releases)
repackage_releases.process(repackaged_releases_path, base_git_clones_path, logs_path)
