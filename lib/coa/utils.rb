module Coa
  # This module ease communication with 3rd party interfaces such as bosh,
  # the shell, etc.
  module Utils
    require_relative './utils/bosh'
    require_relative './utils/coa_logger'
    require_relative './utils/command_runner'
    require_relative './utils/concourse'
  end
end
