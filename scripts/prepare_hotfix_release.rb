#!/usr/bin/env ruby

require 'optparse'

HOTFIX_RELEASE_NOTES_FILENAME = 'hotfix_release_notes.md'
HOTFIX_VERSION_FILENAME = 'hotfix.version'

def create_hotfix_version(version)
  version_file = File.join(File.dirname(__FILE__), '..', HOTFIX_VERSION_FILENAME)
  File.open(version_file, 'w+') { |file| file.write(version) }

end


def create_hotfix_release_note_template(version)
  release_notes = <<~MD
  #Hotfix release
  ## [v#{version}](https://github.com/orange-cloudfoundry/cf-ops-automation/tree/v#{version})
  
  **Fixed bugs:**
  
  - TODO
  MD
  release_notes_file = File.join(File.dirname(__FILE__), '..', HOTFIX_RELEASE_NOTES_FILENAME)
  File.open(release_notes_file, 'w+') { |file| file.write(release_notes) }
end



options = {
    version: ''
}
cmd_line_parser = OptionParser.new do |parser|
  parser.banner = "Usage: #{parser.program_name} [options]"

  parser.on("-v", "--version VERSION",
            "hotfix version to initialize like v<x.y.z>: v1.1.1") do |v_string|
    options[:version] = v_string if v_string =~ /\d{1,2}\.\d{1,2}\.\d{1,2}/
  end
end

cmd_line_parser.parse!
hotfix_version = options.fetch(:version)
if hotfix_version.empty?
  puts cmd_line_parser
  exit(1)
end

create_hotfix_version(hotfix_version)
create_hotfix_release_note_template(hotfix_version)
