#!/usr/bin/env ruby
#
# Copyright (C) 2015-2018 Orange
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
class String
  def black
    "\e[30m#{self}\e[0m"
  end

  def red
    "\e[31m#{self}\e[0m"
  end

  def green
    "\e[32m#{self}\e[0m"
  end
end

class DeletePlan
  def self.process
    deployments_file = ENV.fetch('DEPLOYMENTS_FILE', File.join('deployments-to-delete', 'file.txt'))
    deployments_data = ENV['DEPLOYMENTS_TO_DELETE']
    raise "missing environment variable: DEPLOYMENTS_TO_DELETE" if deployments_data.to_s.empty?

    deployments = deployments_data.split(' ')

    deployments.each do |name|
      display_inactive_message(name)
      append_deployment_name_to_file(name, deployments_file)
    end
  end

  def self.append_deployment_name_to_file(name, deployments_file)
    File.open(deployments_file, 'a') { |file| file.puts name.to_s }
  end

  def self.display_inactive_message(name)
    puts "#{name.red} deployment has been detected as 'inactive', ie :\n" \
      "\t  - paas-template contains deployment descriptors\n" \
      "\t  - secrets does not enable this deployment\n" \
      "\tThis bosh deployment is going to be deleted when exists.\n" \
      "\tOtherwise deletion is run on an unknown deployment.\n" \
      "\t! Waiting for manual approval !\n" \
      ''
  end

  private_class_method :append_deployment_name_to_file, :display_inactive_message
end

DeletePlan.process
