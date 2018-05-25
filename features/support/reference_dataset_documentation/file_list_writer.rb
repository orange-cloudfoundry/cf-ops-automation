module ReferenceDatasetDocumentation
  class FileListWriter
    def initialize(generator)
      @generator = generator
    end

    def perform
      write_config_file_list
      write_template_file_list
    end

    private

    def write_config_file_list
      write_file_list(@generator.config_repo_path, @generator.config_repo_name, "config")
    end

    def write_template_file_list
      write_file_list(@generator.template_repo_path, @generator.template_repo_name, "template")
    end

    def write_file_list(repo_path, repo_name, name)
      Dir.chdir(File.join(repo_path, @generator.root_deployment_name)) do
        list = `find .`
        @generator.add("## The #{name} files", "")
        pretty_list(list, repo_name)
        @generator.add ""
      end
    end

    def pretty_list(list, repo_name)
      new_list = []

      list.each_line do |line|
        new_list << pretty_filepath(line, repo_name)
      end

      new_list.delete_if(&:empty?).each { |item| @generator.add(item) }
    end

    def pretty_filepath(path, repo_name)
      striped_path = path.strip
      path_items = striped_path.split('/')
      filename = path_items.last
      return "" if filename[0] == "."
      prefix = "  " * (path_items.size - 2)
      clean_path = striped_path.gsub(%r{^.\/}, "")
      "#{prefix}* [#{filename}](/docs/reference_dataset/#{repo_name}/#{@generator.example_type}/#{@generator.root_deployment_name}/#{clean_path})"
    end
  end
end
