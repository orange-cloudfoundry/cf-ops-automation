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
require_relative './resolve_manifest_versions'
require_relative './resolve_manifest_urls'
require_relative '../../../lib/tasks'
require 'yaml'

puts __FILE__

versions_file = ENV['VERSIONS_FILE']
stemcell_name = ENV['STEMCELL_NAME']
manifest_file = ENV['MANIFEST_YAML_FILE']
deployment_name = ENV['DEPLOYMENT_NAME']

manifest = versions = {}
versions = YAML.load_file(versions_file, aliases: true) || {} if File.exist?(versions_file)
manifest = YAML.load_file(manifest_file, aliases: true) || {} if File.exist?(manifest_file)

puts "Warning: no version detected !" if versions.empty?
puts "Warning: no manifest detected !" if manifest.empty?

resolve_manifest = ResolveManifestVersions.new(deployment_name, manifest)
resolve_manifest.process(versions, stemcell_name)

stemcell_version = versions.dig('stemcell', 'version')
factory_config = ENV.to_h.dup
factory_config['STEMCELL_VERSION'] = stemcell_version
factory = ResolveManifestReleaseUrlFactory.factory(factory_config)
releases_url_resolver = factory.select_resolver
# releasesUrlResolver = ResolveManifestReleasesUrl.new(deployment_name, download_server_url, offline_mode_enabled)
resolve_manifest_urls = ResolveManifestUrls.new(deployment_name, releases_url_resolver)
resolve_manifest_urls.process(manifest, versions)
