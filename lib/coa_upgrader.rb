# Set of feature to ease creation of upgrade scripts for COA
module CoaUpgrader
  require_relative 'coa_upgrader/command_line_parser'
end

class String
  def black
    "\e[30m#{self}\e[0m"
  end

  def red
    "\e[31m#{self}\e[0m"
  end

  def green
    "\e[32m#{self}\e[0m"
  end

  def yellow
    "\e[33m#{self}\e[0m"
  end
end
