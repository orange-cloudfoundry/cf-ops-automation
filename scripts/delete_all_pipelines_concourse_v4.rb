require 'json'

fly_target = ENV.fetch('FLY_TARGET', 'bucc')
pipelines = JSON.parse `fly -t #{fly_target} ps --json`

pipelines.each do |pipeline|
  cmd = "fly -t #{fly_target} dp -p #{pipeline['name']} -n"
  puts cmd
  `#{cmd}`
end
