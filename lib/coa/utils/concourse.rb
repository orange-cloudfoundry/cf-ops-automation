module Coa
  module Utils
    # This module helps using Concourse.
    module Concourse
      require_relative 'concourse/build'
      require_relative 'concourse/concourse'
      require_relative 'concourse/config'
      require_relative 'concourse/fly'
      require_relative 'concourse/job'
      require_relative 'concourse/pipeline'
    end
  end
end
