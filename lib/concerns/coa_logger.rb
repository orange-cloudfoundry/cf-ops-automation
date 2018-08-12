require 'logger'

# This utility module helps having a central logging mechanism
module CoaLogger
  def logger
    @logger ||=
      begin
        logger_path = File.join(File.dirname(__FILE__), '/../..', "log", "stdout.log")
        Logger.new(logger_path)
      end
  end
end

# Here, we monkey-patch Logger
class Logger
  def log_and_puts(severity, message)
    severity = Object.const_get("Logger::#{severity.to_s.upcase}")
    puts message
    log(severity, message)
  end
end
