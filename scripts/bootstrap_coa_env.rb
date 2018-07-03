require_relative '../lib/coa_env_bootstrapper'

if ARGV[0].nil?
  puts "Usage: ./script/bootstrap-coa-env.rb </path/to/prereqs-1.yml> </path/to/prereqs-2.yml> ... </path/to/prereqs-n.yml>"
else
  CoaEnvBootstrapper.new(ARGV).execute
end
