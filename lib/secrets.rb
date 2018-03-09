
class Secrets
  attr_reader :secrets_root_dir

  def initialize(secrets_root)
    @secrets_root_dir = secrets_root
  end

  def overview
    dir_overview = {}

    Dir[@secrets_root_dir].select { |file_or_dir| File.directory? file_or_dir }
                          .each do |depls_level_dir|
      depls_level_name = depls_level_dir.split('/').last
      puts "Processing Secrets depls level: #{depls_level_name}"
      dir_overview[depls_level_name] = subdir_overview(depls_level_dir, depls_level_name)
    end
    dir_overview
  end

  private

  def subdir_overview(depls_level_dir, depls_level_name)
    overview = []
    Dir[depls_level_dir + '/*'].select { |file_or_dir| File.directory? file_or_dir }
                               .each do |boshrelease_level_dir|
      boshrelease_level_name = boshrelease_level_dir.split('/').last
      puts "Processing Secrets boshrelease level: #{depls_level_name} -- #{boshrelease_level_name}"
      overview << boshrelease_level_name
    end
    overview
  end
end
