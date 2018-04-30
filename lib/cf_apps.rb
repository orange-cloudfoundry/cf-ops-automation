require 'yaml'

class CfApps
  attr_reader :base_path, :root_deployment_name

  def initialize(path, root_deployment_name)
    @base_path = path
    @root_deployment_name = root_deployment_name
  end

  def overview
    cf_apps = {}
    puts "Path CF App: #{base_path}"

    Dir[base_path].select { |file| File.directory? file }.each do |base_subdir|
      collect_cf_apps_details(base_subdir, cf_apps)
    end

    puts "cf_apps: \n#{YAML.dump(cf_apps)}"
    cf_apps
  end

  def self.enable_cf_app_files(dir)
    Dir.glob(dir + '/**/enable-cf-app.yml')
  end

  private

  def collect_cf_apps_details(base_subdir, cf_apps)
    subdir_name = File.basename(base_subdir)
    puts "Processing CF App: #{subdir_name}"

    self.class.enable_cf_app_files(base_subdir).each do |enable_cf_app_file|
      load_cf_apps_details_from_file(cf_apps, enable_cf_app_file, base_subdir)
    end

    cf_apps
  end

  def load_cf_apps_details_from_file(cf_apps, file, subdir)
    puts "Cf App detected: #{subdir} - #{file}"
    dir = File.dirname(file)
    cf_apps_description = YAML.load_file(file)

    cf_apps_description['cf-app'].each do |cf_app_name, cf_app_details|
      cf_apps[cf_app_name] = load_cf_app_details(cf_app_name, cf_app_details, file, dir, cf_apps)
    end
  end

  def load_cf_app_details(cf_app_name, cf_app_details, file, dir, cf_apps)
    puts "processing cf-app: #{cf_app_name} from #{file}"
    raise "cannot process #{file}, an application named #{cf_app_name} already exists" if cf_apps.key?(cf_app_name)
    #   raise "#{dependency_file} - Invalid deployment: expected <#{dirname}> - Found <#{deployment_name}>" if deployment_name != dirname
    cf_app_details['base-dir'] = dir.sub(/^.*#{Regexp.escape(root_deployment_name)}/, root_deployment_name)
    cf_app_details
  end
end
