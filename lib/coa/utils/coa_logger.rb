require 'logger'

module Coa
  module Utils
    module CoaLogger
      # This utility module helps having a central logging mechanism.
      def self.included(base)
        base.extend(ClassMethods)
      end

      # This module lets us write class method the the CoaLogger module.
      module ClassMethods
        def logger
          current_dir =  File.dirname(__FILE__)
          default_path = File.join('..', '..', '..', 'log')
          log_filename = File.join(current_dir, ENV.fetch('COA_LOG_PATH', default_path), "stdout.log")
          Logger.new(log_filename)
        end
      end

      def logger
        @logger ||= self.class.logger
      end
    end
  end
end

# Monkey-patching Logger.
class Logger
  def log_and_puts(severity, message)
    severity = Object.const_get("Logger::#{severity.to_s.upcase}")
    puts message
    log(severity, message)
  end
end
