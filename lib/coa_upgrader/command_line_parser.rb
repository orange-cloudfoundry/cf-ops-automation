require 'optparse'

module CoaUpgrader
  # Common command line parsing for upgrade scripts
  class CommandLineParser
    OPTIONS = {
      dump_output: true,
      config_path: '',
      templates_path: ''
    }.freeze

    def initialize(options = OPTIONS.dup)
      @options = options
    end

    def parse
      options = @options
      opt_parser = OptionParser.new do |opts|
        opts.banner = "Incomplete/wrong parameter(s): #{opts.default_argv}.\n Usage: ./#{opts.program_name} <options>"

        opts.on('-c', '--config PATH', "config-path location (main git directory). Default: #{options[:config_path]}") do |cp_string|
          options[:config_path] = cp_string
        end

        opts.on('-t', '--templates PATH', "paas-templates path location (main git directory). Default: #{options[:templates_path]}") do |tp_string|
          options[:templates_path] = tp_string
        end

        opts.on('--[no-]dump', 'Dump genereted file on standart output') do |dump|
          options[:dump_output] = dump
        end
      end
      opt_parser.parse!
      @options = options
    end
  end
end
