module Coa
  module Utils
    # This module helps using Concourse.
    module Concourse
      require_relative 'concourse/build'
      require_relative 'concourse/client'
      require_relative 'concourse/config'
      require_relative 'concourse/fly'
    end
  end
end
