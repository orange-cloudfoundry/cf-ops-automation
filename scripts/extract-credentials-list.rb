#!/usr/bin/env ruby -w


def credential_list(pipelines_path)
  creds_list = []

  files = File.directory?(pipelines_path) ? Dir["#{pipelines_path}/*"] : [pipelines_path]

  files.each do |path|
    next if File.directory?(path)
    pipeline_content = File.read(path)
    creds_list << pipeline_content.scan(/\(\(([\w|-]*)\)\)/).flatten.uniq
  end

  creds_list.flatten.uniq
end

path = ARGV[0]
creds = credential_list(path)
puts creds.join("\n")
