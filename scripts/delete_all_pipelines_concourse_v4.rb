require 'json'

pipelines = JSON.parse `fly -t bucc ps --json`

pipelines.each do |pipeline|
  cmd = "fly -t bucc dp -p #{pipeline['name']} -n"
  puts cmd
  `#{cmd}`
end
