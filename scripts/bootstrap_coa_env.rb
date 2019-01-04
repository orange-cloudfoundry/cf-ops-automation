#!/usr/bin/env ruby

require_relative '../lib/coa/env_bootstrapper/runner'

# TODO: install bucc if not present and needed
# Dir.chdir 'bin' do
#   `git clone https://github.com/starkandwayne/bucc`
#   Dir.chdir 'bucc' do
#    `git checkout v0.5.0` # concourse v3
#   end
# end

# TODO: add docu + usage
# load local/dev (= bucc + virtualbox) as fallback
prereqs_paths =
  if ENV["PREREQS_PATHS_RAW"]
    ENV["PREREQS_PATHS_RAW"].split(" ")
  elsif ARGV.length.positive?
    ARGV
  else
    [
      "ci/bootstrap_coa_env/*-prereqs.yml",
      "ci/bootstrap_coa_env/virtualbox/*-prereqs.yml", # NOTE: maybe make this an arg? make iaas an arg?
      "ci/bootstrap_coa_env/bucc/*-prereqs.yml"
    ]
  end

relative_paths = Dir.glob(prereqs_paths)
absolute_paths = relative_paths.map { |rp| File.absolute_path(rp) }

Coa::EnvBootstrapper::Runner.run_from_prereqs(absolute_paths)
