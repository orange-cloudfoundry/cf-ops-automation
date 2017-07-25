
class Secrets
  attr_reader :secrets_root_dir

  def initialize(secrets_root)
    @secrets_root_dir = secrets_root
  end

  def overview
    dir_overview = {}

    Dir[@secrets_root_dir].select { |f| File.directory? f }.each do |depls_level_dir|
      depls_level_name = depls_level_dir.split('/').last
      puts "Processing depls level: #{depls_level_name}"
      dir_overview[depls_level_name] = []
      Dir[depls_level_dir + '/*'].select { |f| File.directory? f }.each do |boshrelease_level_dir|
        boshrelease_level_name= boshrelease_level_dir.split('/').last
        puts "Processing boshrelease level: #{depls_level_name} -- #{boshrelease_level_name}"
        dir_overview[depls_level_name] << boshrelease_level_name
      end
    end
    dir_overview
  end


end