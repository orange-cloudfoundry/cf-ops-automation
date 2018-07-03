#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'

FileUtils.mkdir_p "private-prereqs"

puts "current env:", ENV.inspect

if ENV["OWN_CONCOURSE"] == "true"
  concourse_prereqs_path = "private-prereqs/concourse-prereqs.yml"
  puts "Creating Concourse credentials file at '#{concourse_prereqs_path}'"

  concourse_prereqs = {
    "concourse" => {
      "concourse_target"   => ENV["CONCOURSE_TARGET"],
      "concourse_url"      => ENV["CONCOURSE_URL"],
      "concourse_username" => ENV["CONCOURSE_USERNAME"],
      "concourse_password" => ENV["CONCOURSE_PASSWORD"],
      "concourse_insecure" => ENV["CONCOURSE_INSECURE"],
      "concourse_ca_cert"  => ENV["CONCOURSE_CA_CERT"]
    }
  }

  File.write(concourse_prereqs_path, concourse_prereqs.to_yaml)
end

if ENV["OWN_BOSH"] == "true"
  bosh_prereqs_path = "private-prereqs/bosh-prereqs.yml"
  puts "Creating BOSH credentials file at '#{bosh_prereqs_path}'"

  bosh_prereqs = {
    "bosh" => {
      "bosh_environment"   => ENV["BOSH_ENVIRONMENT"],
      "bosh_target"        => ENV["BOSH_TARGET"],
      "bosh_client"        => ENV["BOSH_CLIENT"],
      "bosh_client_secret" => ENV["BOSH_CLIENT_SECRET"],
      "bosh_ca_cert"       => ENV["BOSH_CA_CERT"]
    }
  }

  File.write(bosh_prereqs_path, bosh_prereqs.to_yaml)
end
