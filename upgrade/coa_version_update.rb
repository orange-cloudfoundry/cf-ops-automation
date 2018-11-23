#!/usr/bin/env ruby

require 'yaml'
require 'open3'
require 'json'
require 'optparse'

class CommandLineParser
  OPTIONS = {
    concourse_url: '',
    concourse_username: 'atc',
    concourse_password: '',
    concourse_target: 'coa-version',
    coa_version: ''
  }.freeze

  def initialize(options = OPTIONS.dup)
    @options = options
  end

  def parse
    options = @options
    opt_parser = OptionParser.new do |opts|
      opts.banner = "Incomplete/wrong parameter(s): #{opts.default_argv}.\n Usage: ./#{opts.program_name} <options>"

      opts.on('-c', '--config URL', "MANDATORY - concourse url. Default: #{options[:concourse_url]}") do |c_string|
        options[:concourse_url] = c_string
      end

      opts.on('-v', '--version VERSION', 'MANDATORY - coa version to switch to v<x.y.z>') do |v_string|
        options[:coa_version] = v_string if v_string =~ /v\d{1,2}\.\d{1,2}\.\d{1,2}/
      end

      opts.on('-p', '--password VALUE', "MANDATORY - concourse admin password. Default: #{options[:concourse_password]}") do |p_string|
        options[:concourse_password] = p_string
      end

      opts.on('-u', '--username VALUE', "concourse admin username. Default: #{options[:concourse_username]}") do |u_string|
        options[:concourse_username] = u_string
      end

      opts.on('-t', '--target VALUE', "concourse target name. Default: #{options[:concourse_target]}") do |t_string|
        options[:concourse_target] = t_string
      end
    end
    opt_parser.parse!
    raise OptionParser::MissingArgument, "'concourse_url', please check required parameter using --help" if options[:concourse_url].to_s.empty?
    raise OptionParser::MissingArgument, "'concourse_password', please check required parameter using --help" if options[:concourse_password].to_s.empty?

    @options = options
  end
end


class CoaVersionUpdate
  COA_RESOURCE_NAME = 'cf-ops-automation'.freeze

  def initialize(options)
    @config = options

    @fly_target_base = @config[:concourse_target]
    @fly_main = Fly.new(@fly_target_base)
    @coa_version = @config[:coa_version]
  end

  def run

    concourse_url = @config[:concourse_url]
    concourse_password = @config[:concourse_password]
    concourse_username = @config[:concourse_username]
    @fly_main.login(url = concourse_url, password = concourse_password)
    puts "Teams:"
    teams = @fly_main.teams
    logged = teams.map do |team|
      fly_current_team = Fly.new("#{@fly_target_base}-#{team}")
      fly_current_team.login(concourse_url, team, concourse_username, concourse_password)
    end
    logged.each do |current_fly|
      puts "Pipelines:"
      pipelines = current_fly.pipelines
      pipelines.each do |name, _|
        coa_version = @coa_version
        begin
          check_output = current_fly.check_resource(name, COA_RESOURCE_NAME, coa_version)
          puts check_output
        rescue FlyError => fly_error
          raise fly_error unless fly_error.message =~ /resource 'cf-ops-automation' not found/
          puts " > Ignoring #{name}, resource #{COA_RESOURCE_NAME} not found"
        end
      end
    end
  end

end

class Fly
  def initialize(target)
    @target = target
  end

  def fly(arg, env = {})
    env_var = env.collect { |k, v| "#{k}=#{v}" }.join(' ')
    out, err, status = Open3.capture3("env #{env_var} fly --target #{@target} #{arg} | tee /tmp/fly.log")
    raise FlyError, "Failed: env #{env_var} fly --target #{@target} #{arg} | tee /tmp/fly.log\n #{err unless err.empty? } " if !status.success? or !err.empty? #err =~ /error: websocket: bad handshake/
    out
  end

  def login(url, team = 'main', username = 'atc', password, insecure:false, env:{})
    options = ''
    options += '--insecure ' if insecure
    puts "login --team-name #{team} -u #{username} -p **redacted** -c #{url} #{options}"
    fly("login --team-name #{team} -u #{username} -p #{password} -c #{url} #{options}", env)
    self
  end

  def execute(cmd, env = {})
    fly("execute #{cmd}", env)
  end

  def teams(env = {})
    teams = []
    output = fly("teams", env)
    output.each_line do |line|
      teams << line.rstrip unless line.to_s.empty?
    end
    teams
  end

  def pipelines(env = {})
    pipelines = {}
    output = fly("pipelines", env)
    output.each_line do |line|
      matches = line.match /^([\w|-]+)\s+(\w*)\s+(\w*)/
      next if matches.nil?
      name = matches[1]
      paused = matches[2]
      public = matches[3]
      pipelines[name] = { paused: paused == 'yes', public: public == 'yes' }
    end
    pipelines
  end

  def check_resource(pipeline, resource_name, version = '',env = {})
    puts "Checking #{pipeline}/#{resource_name}: #{+ version}"
    check_resource_cmd = "check-resource --resource #{pipeline}/#{resource_name}"
    check_resource_cmd += " -from ref:#{version} " unless version.empty?
    fly(check_resource_cmd, env)
  end

end
class FlyError < RuntimeError; end

options = CommandLineParser.new.parse

CoaVersionUpdate.new(options).run