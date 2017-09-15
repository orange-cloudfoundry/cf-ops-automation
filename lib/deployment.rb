require 'yaml'

class Deployment
  attr_reader :name, :details

  def initialize(deployment_name, details = {})
    @name = deployment_name
    @details = details
  end

  def enabled?
    details['status'] == 'enabled'
  end

  def disabled?
    details['status'].nil? || details['status'] == 'disabled'
  end

  def enable
    new_details = @details.dup
    new_details['status'] = 'enabled'

    Deployment.new(@name, new_details)
  end

  def disable
    new_details = @details.dup
    new_details['status'] = 'disabled'

    Deployment.new(@name, new_details)
  end

  def self.default(deployment_name)
    details = {
           'stemcells' => {'bosh-openstack-kvm-ubuntu-trusty-go_agent' => ''},
           'releases' => {}
           }
    Deployment.new(deployment_name, details)
  end
end


class DeploymentBuilder

  def initialize
    @name = ''
    @details = {}
  end

  def name(name)
    @name = name
    self
  end

  def add_details(details)
    @details.merge!(details)
    self
  end

  def enable
    details['status'] = 'enabled'
    self
  end

  def disable
    details['status'] = 'disabled'
    self
  end

  def build
    Deployment.new(@name, @details)
  end

end

