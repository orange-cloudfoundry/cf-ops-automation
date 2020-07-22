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
require_relative './repackage_releases_fallback'

puts __FILE__

repackaged_releases_fallback_path = ENV['REPACKAGED_RELEASES_FALLBACK_PATH']
raise 'FATAL: Missing repackaged_releases_fallback_path' if repackaged_releases_fallback_path.to_s.empty?

repackaged_releases_path = ENV['REPACKAGED_RELEASES_PATH']
raise 'FATAL: Missing repackaged_releases_path' if repackaged_releases_path.to_s.empty?

repackaged_error_filepath = ARGV[0]
repackage_releases_fallback = RepackageReleasesFallback.new(repackaged_error_filepath)
repackage_releases_fallback.process(repackaged_releases_fallback_path, repackaged_releases_path)
