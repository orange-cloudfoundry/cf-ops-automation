require 'yaml'

class Deployment
  attr_reader :name, :details

  def initialize(deployment_name, details)
    @name = deployment_name
    @details = details
  end

end
