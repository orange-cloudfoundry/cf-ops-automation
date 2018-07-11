#!/usr/bin/env ruby -w

# scan pipelines to list concourse variables
class CredentialsList
  def self.list(pipelines_path)
    creds_list = []

    files = File.directory?(pipelines_path) ? Dir["#{pipelines_path}/*"] : [pipelines_path]

    files.each do |path|
      next if File.directory?(path)
      pipeline_content = File.read(path)
      creds_list << pipeline_content.scan(/\(\(([\w|-]*)\)\)/).flatten.uniq
    end

    creds_list.flatten.uniq.sort
  end
end

if (path = ARGV[0])
  creds = CredentialsList.list(path)
  puts "Found credentials in alphabetical order:"
  puts creds.join("\n")
else
  puts "Usage:\n./scripts/extract_pipeline_credentials_list.rb </path/to/pipeline> OR\n./scripts/extract_pipeline_credentials_list.rb </path/to/pipelines/directory>"
end
