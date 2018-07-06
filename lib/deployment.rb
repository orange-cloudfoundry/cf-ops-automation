require 'yaml'

class Deployment
  attr_reader :name, :details

  def initialize(deployment_name, details = {})
    @name = deployment_name
    @details = {}
    @details = details unless details.nil?
  end

  def enabled?
    details['status'] == 'enabled'
  end

  def disabled?
    details['status'].nil? || details['status'] == 'disabled'
  end

  def enable
    details['status'] = 'enabled'
    self
  end

  def disable
    details['status'] = 'disabled'
    self
  end

  def self.default(deployment_name)
    Deployment.new(deployment_name, default_details)
  end

  def self.default_details
    {
      'stemcells' => {},
      'releases' => {}
    }
  end
end
