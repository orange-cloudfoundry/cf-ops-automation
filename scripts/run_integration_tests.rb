#!/usr/bin/env ruby

require_relative '../lib/coa/integration_tests'

# TODO: add docu + usage
# load local/dev (= bucc + virtualbox) as fallback
prereqs_paths =
  if ENV["PREREQS_PATHS_RAW"]
    ENV["PREREQS_PATHS_RAW"].split(" ")
  else
    [
      "ci/bootstrap_coa_env/*-prereqs.yml",
      "ci/bootstrap_coa_env/virtualbox/*-prereqs.yml",
      "ci/bootstrap_coa_env/bucc/*-prereqs.yml"
    ]
  end

relative_paths = Dir.glob(prereqs_paths)
absolute_paths = relative_paths.map { |path| File.absolute_path(path) }

tests = Coa::IntegrationTests.new(absolute_paths)

tests.run
