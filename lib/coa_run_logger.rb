require 'logger'

module CoaRunLogger
  # This utility module helps having a central logging mechanism.
  def self.included(base)
    base.extend(ClassMethods)
  end

  # This module lets us write class method the the CoaLogger module.
  module ClassMethods
    def logger
      current_dir =  File.dirname(__FILE__)
      default_path = '..' #File.join('..', '..', '..', 'log')
      log_filename = File.join(current_dir, ENV.fetch('COA_LOG_PATH', default_path), "coa_run_stdout.log")
      Logger.new(log_filename)
    end
  end

  def logger
    @logger ||= self.class.logger
  end
end
