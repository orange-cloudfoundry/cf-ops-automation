class GitModules
  attr_accessor :path

  def initialize(base_path)
    @path = "#{base_path}/.gitmodules"
  end

  def list
    return {} unless File.exist? path

    git_modules_file = File.open(path)
    git_submodules = extract_submodules(git_modules_file)
    git_modules_file.close

    git_submodules
  end

  private

  def extract_submodules(git_modules_file)
    paths = select_paths(git_modules_file)
    cleaned_paths = clean_paths(paths)
    select_submodules(cleaned_paths)

    git_submodules
  end

  def select_paths(git_modules_file)
    git_modules_file.select do |line|
      line.strip!.start_with?('path =')
    end
  end

  def clean_paths(paths)
    paths.each do |path|
      path[0..6] = ''
    end
  end

  def select_submodules(clean_paths)
    git_submodules = {}

    clean_paths.each do |path|
      parsed_path = path.split('/')
      next if parsed_path.length > 2

      current_depls = parsed_path[0]
      git_submodules[current_depls] = {} unless git_submodules[current_depls]

      current_deployment = parsed_path[1]
      item = { current_deployment => [path] }

      if git_submodules[current_depls][current_deployment]
        git_submodules[current_depls][current_deployment] << path
      else
        git_submodules[current_depls].merge! item
      end
    end

    git_submodules
  end
end
