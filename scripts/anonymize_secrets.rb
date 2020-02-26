#!/usr/bin/env ruby
require 'yaml'
require 'optparse'
require 'find'
require 'tmpdir'
require 'rhcl'

# Argument parsing
OPTIONS = {
  output_path: Dir.mktmpdir("secrets-"),
  secrets_path: nil
}.freeze

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: ./#{opts.program_name} <options>"

  opts.on("-s", "--secrets PATH", "Specify a secrets directory to be anonymized. MANDATORY") do |secrets_string|
    OPTIONS[:secrets_path] = secrets_string
  end

  opts.on("-o", "--output-path PATH", "Output path to export yaml secrets key. Default: /tmp/secrets-xxxxxxx") do |op_string|
    OPTIONS[:output_path] = op_string
  end
end
opt_parser.parse!
opt_parser.abort(opt_parser.to_s) if OPTIONS[:secrets_path].nil?

def header(msg)
  print '*' * 10
  puts " #{msg}"
end

def cleanup_secrets(hash)
  # puts "> #{hash.inspect}"
  cleanup_hash(hash) if hash.is_a?(Hash)

  cleanup_arrays(hash) if hash.is_a?(Array)

  # puts "< #{hash.inspect}"
  hash
end

def cleanup_hash(an_hashmap)
  an_hashmap.each do |secret_key, value|
    # puts "Processing hash[#{secret_key}] = #{value}"
    # puts "  #{value} is a #{value.class}"
    # hash[secret_key]=value.class.to_s if value.is_a?(String) || value.is_a?(Numeric)
    an_hashmap[secret_key] = value.class.to_s if !value.is_a?(Hash) || value.is_a?(Array)
    an_hashmap[secret_key] = cleanup_secrets(value) if value.is_a?(Hash) || value.is_a?(Array)
  end
  an_hashmap
end

def cleanup_arrays(an_array)
  an_array.each_index do |index|
    value = an_array[index]
    # puts "Processing hash[#{index}] = #{value}"
    # puts "  #{value} is a #{value.class}"
    # hash[secret_key]=value.class.to_s if value.is_a?(String) || value.is_a?(Numeric)
    an_array[index] = value.class.to_s if !value.is_a?(Hash) || value.is_a?(Array)
    an_array[index] = cleanup_secrets(value) if value.is_a?(Hash) || value.is_a?(Array)
  end
  an_array
end

def create_missing_dir(new_secret_filename)
  full_path = ""
  File.dirname(new_secret_filename).split("/").each do |path_item|
    full_path += "#{path_item}/"
    target_path = "#{OPTIONS[:output_path]}/#{full_path}"
    # puts ">> creating #{target_path} if required"
    Dir.mkdir(target_path) unless Dir.exist?(target_path)
  end
end

def extract_secrets_keys(selected_yaml_file)
  file_counter = 0
  selected_yaml_file.each do |filename|
    current_secrets_yaml = YAML.load_file(filename)
    new_secret_filename = filename.slice(OPTIONS[:secrets_path].length + 1..filename.length)

    puts "> processing #{new_secret_filename}"
    file_counter += 1

    secrets_keys = cleanup_secrets(current_secrets_yaml)

    create_missing_dir(new_secret_filename)

    secrets_keys_file = File.new("#{OPTIONS[:output_path]}/#{new_secret_filename}", "w")
    secrets_keys_file << YAML.dump(secrets_keys)
  end
  file_counter
end

def selected_yaml_secrets_files(path)
  selected_files = []
  Dir[path].each do |filename|
    selected_files << filename if include_yaml_file? filename
  end

  selected_files
end

def include_yaml_file?(filename)
  name_without_extension = File.basename(filename, ".*")
  file_path = File.dirname(filename)

  return false if name_without_extension.end_with? "-generated"

  return true if !file_path.include?(name_without_extension) || name_without_extension == "secrets"

  false
end

def selected_tfvars_secrets_files(path)
  selected_files = []
  Dir[path].each do |filename|
    selected_files << filename
  end

  selected_files
end

def cleanup_tfvars_secrets(secrets_tfvars)
  secrets_tfvars.keys
end

def anonymize_tfvars_files(selected_tfvars_secrets)
  file_counter = 0
  selected_tfvars_secrets.each do |filename|
    current_secrets_tfvars = File.read(filename)

    new_secret_filename = filename.slice(OPTIONS[:secrets_path].length + 1..filename.length)

    puts "> processing #{new_secret_filename}"
    file_counter += 1

    parsed_secrets = Rhcl.parse(current_secrets_tfvars)
    anonymized_secrets = cleanup_tfvars_secrets(parsed_secrets)

    create_missing_dir(new_secret_filename)

    anonymized_secrets_file = File.new("#{OPTIONS[:output_path]}/#{new_secret_filename}", "w")
    anonymized_secrets_file << YAML.dump(anonymized_secrets)
  end
  file_counter
end

Dir.mkdir((OPTIONS[:output_path]).to_s) unless Dir.exist?((OPTIONS[:output_path]).to_s)

# processed_files=extract_secrets_keys("#{OPTIONS[:deployment_dependencies_path]}/shared/secrets.yml")
# processed_files=extract_secrets_keys("#{OPTIONS[:secrets_path]}/micro-depls/nexus/nexus.yml")
selected_yaml_secrets = selected_yaml_secrets_files("#{OPTIONS[:secrets_path]}/**/*.yml")
yaml_processed_files = extract_secrets_keys(selected_yaml_secrets)

selected_tfvars_secrets = selected_tfvars_secrets_files("#{OPTIONS[:secrets_path]}/**/*.tfvars")
tfvars_processed_files = anonymize_tfvars_files(selected_tfvars_secrets)

# puts OPTIONS.inspect
puts
puts
puts "#{yaml_processed_files} yaml files have been anonymized at #{OPTIONS[:output_path]}"
puts "#{tfvars_processed_files} tfvars files have been anonymized at #{OPTIONS[:output_path]}"
puts
puts 'Thanks, Orange CloudFoundry SKC'
