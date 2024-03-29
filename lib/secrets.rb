require_relative 'coa_run_logger'
class Secrets
  attr_reader :secrets_root_dir

  include CoaRunLogger
  def initialize(secrets_root)
    @secrets_root_dir = secrets_root
  end

  def overview
    dir_overview = {}

    Dir[@secrets_root_dir].select { |item| File.directory? item }.each do |depls_level_dir|
      depls_level_name = depls_level_dir.split('/').last
      logger.info "Processing Secrets depls level: #{depls_level_name}"
      dir_overview[depls_level_name] = subdir_overview(depls_level_dir, depls_level_name)
    end

    dir_overview.sort
  end

  private

  def subdir_overview(depls_level_dir, depls_level_name)
    overview = []
    Dir[depls_level_dir + '/*'].select { |item| File.directory? item }.each do |boshrelease_level_dir|
      boshrelease_level_name = boshrelease_level_dir.split('/').last
      logger.info "Processing Secrets boshrelease level: #{depls_level_name} -- #{boshrelease_level_name}"
      overview << boshrelease_level_name
    end
    overview.sort
  end
end
