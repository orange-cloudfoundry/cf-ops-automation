require 'yaml'

class CfAppOverview
  attr_reader :base_dir, :root_deployment_name

  def initialize(path, root_deployment_name)
    @base_dir = path
    @root_deployment_name = root_deployment_name
  end

  def overview
    cf_apps = {}
    puts "Path CF App: #{@base_dir}"

    Dir[@base_dir].select { |f| File.directory? f }.each do |base_dir|
      dirname = base_dir.split('/').last
      puts "Processing CF App: #{dirname}"
      Dir.glob(base_dir + '/**/enable-cf-app.yml').each do |enable_cf_app_file|
        puts "Cf App detected: #{base_dir} - #{enable_cf_app_file}"
        enable_cf_app_file_dir = File.dirname(enable_cf_app_file)
        cf_app_desc = YAML.load_file(enable_cf_app_file)
        cf_app_desc['cf-app'].each do |cf_app_name, cf_app_details|
          puts "processing cf-app: #{cf_app_name} from #{enable_cf_app_file}"
          raise "cannot process #{enable_cf_app_file}, an application named #{cf_app_name} already exists" if cf_apps.has_key?(cf_app_name)
          #   raise "#{dependency_file} - Invalid deployment: expected <#{dirname}> - Found <#{deployment_name}>" if deployment_name != dirname
          cf_app_details['base-dir'] = enable_cf_app_file_dir.sub(/^.*#{Regexp.escape(@root_deployment_name)}/, @root_deployment_name)

          cf_apps[cf_app_name] = cf_app_details
        end
      end
    end
    puts "cf_apps: \n#{YAML.dump(cf_apps)}"
    cf_apps
  end

end