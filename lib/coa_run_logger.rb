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
      default_path = '..' # File.join('..', '..', '..', 'log')
      log_output = ENV.fetch('COA_LOG_OUTPUT', 'File')
      log_filename = File.join(current_dir, ENV.fetch('COA_LOG_PATH', default_path), "coa_run_stdout.log")
      log_filename = $stdout if log_output == 'STDOUT'
      log_level = ENV.fetch('COA_LOG_LEVEL', 'Debug')
      log_dateformat = ENV.fetch('COA_LOG_DATEFORMAT', Logger::Formatter.new.datetime_format)
      Logger.new(log_filename, level: log_level, datetime_format: log_dateformat)
    end
  end

  def logger
    @logger ||= self.class.logger
  end
end
